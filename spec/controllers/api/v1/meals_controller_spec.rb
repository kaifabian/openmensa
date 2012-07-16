require 'spec_helper'

describe Api::V1::MealsController do
  render_views

  let(:json) { JSON[response.body] }

  describe "GET index" do
    let(:canteen) { FactoryGirl.create :canteen }
    before do
      FactoryGirl.create :meal, canteen: canteen, date: Time.zone.now - 2.day
      FactoryGirl.create :meal, canteen: canteen, date: Time.zone.now - 1.day
      FactoryGirl.create :meal, canteen: canteen, date: Time.zone.now
      FactoryGirl.create :meal, canteen: canteen, date: Time.zone.now + 1.day
      FactoryGirl.create :meal, canteen: canteen, date: Time.zone.now + 2.day
    end

    it "should return list of meals" do
      get :index, format: :json, cafeteria_id: canteen.id

      response.status.should == 200
      json.should be_an(Array)
      json.should have(5).item
    end

    context "a meal" do
      it "should have same representation as single resource" do
        get :index, format: :json, cafeteria_id: canteen.id

        meal = json[0]

        get :show, format: :json, cafeteria_id: canteen.id, id: meal["meal"]["id"]

        meal.should == JSON[response.body]
      end
    end
  end

  describe "GET show" do
    let(:canteen) { FactoryGirl.create :canteen }
    let(:meal)    { FactoryGirl.create :meal, canteen: canteen, date: Time.zone.now }

    it "should return a meal object" do
      get :show, format: :json, cafeteria_id: canteen.id, id: meal.id

      response.status.should == 200
      json.should be_an(Hash)

      json["meal"]["id"].should == meal.id
    end

    it "should include meal id" do
      get :show, format: :json, cafeteria_id: canteen.id, id: meal.id
      json["meal"]["id"].should == meal.id
    end
  end
end
