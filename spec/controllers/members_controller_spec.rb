require 'rails_helper'

RSpec.describe MembersController, type: :controller do
  include Devise::Test::ControllerHelpers

  before(:each) do
    request.env["HTTP_ACCEPT"] = 'application/json'

    @request.env["devise.mapping"] = Devise.mappings[:user]
    @current_user = FactoryGirl.create(:user)
    sign_in @current_user
  end

  describe "POST #create" do
    context "all data correct:" do
      before(:each) do
        @campaign = create(:campaign, user: @current_user)
        @member_attributes = attributes_for(:member, campaign_id: @campaign.id)
        post :create, params: { member: @member_attributes }
      end

      it "member created with correct data" do
        expect(response).to have_http_status(:success)
      end

      it "member created is included and has member_attributes in that campaign" do
        expect(Member.last).to have_attributes(@member_attributes)
      end

      it "member created is included in @campaign.members" do
        expect(@campaign.reload.members.last).to match(Member.last)
      end

      it "expect member to be in correct campaign" do
        expect(Member.last.campaign).to eq(@campaign)
      end

      it "but the member is already in - expect count equal" do
        before_count = @campaign.members.count
        @campaign.members << @campaign.members.last
        expect(before_count).to eq(@campaign.reload.members.count)
      end

    context "adding a member that already exists"
      before(:each) do
        @campaign = create(:campaign, user: @current_user)
        @member_attributes = attributes_for(:member, campaign_id: @campaign.id)
        post :create, params: { member: @member_attributes }
      end

      it "returns http status unprocessable_entity" do
        post :create, params: { member: @member_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "forbidden action" do
      before(:each) do
        @other_campaign = create(:campaign)
        @member = create(:member)
        @member_attributes = attributes_for(:member)
        post :create, params: { member: @member_attributes }
      end

      it "campaign user who is not the owner of the campaign cannot add member" do
        expect(response).not_to have_http_status(:created)
      end
    end
  end

  describe "Delete #destroy" do
    context "member must be removed" do
      before(:each) do
        @campaign = create(:campaign, user: @current_user)
        @member = create(:member, campaign: @campaign)
        @before_count = @campaign.members.count
        delete :destroy, params: { id: @member.id }
      end
      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "expect member was removed" do
        expect(@campaign.reload.members.count).not_to eq(@before_count)
      end
    end

    context "member cannot be removed" do
      before(:each) do
        @campaign = create(:campaign)
        @member = create(:member, campaign: @campaign)
        @before_count = @campaign.members.count
        delete :destroy, params: { id: @member.id }
      end

      it "expects forbidden status" do
        expect(response).to have_http_status(:forbidden)
      end

      it "expect nothing changed since member was not removed" do
        expect(@before_count).to eq(@campaign.reload.members.count)
      end

    end
  end

  describe "put #update" do
    context "update done correctly" do
      before(:each) do
        @campaign = create(:campaign, user: @current_user)
        @member = create(:member, campaign: @campaign)
        @new_member_attributes = attributes_for(:member, campaign: @member.campaign)
        put :update, params: { id: @member.id, member: @new_member_attributes }
      end
      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "update successfully" do
        expect(Member.last).to have_attributes(@new_member_attributes)
      end
    end
    context "update when the email already exists" do
      before(:each) do
        @campaign = create(:campaign, user: @current_user)
        @member = create(:member, campaign: @campaign)
        @other_member = create(:member, campaign: @campaign)
        @new_member_attributes = attributes_for(:member, name: @other_member.name, email: @other_member.email, campaign: @member.campaign)
        put :update, params: { id: @member.id, member: @new_member_attributes }
      end

      it "returns http status unprocessable_entity" do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
