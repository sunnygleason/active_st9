require "spec_helper"

describe ActiveRest::IdentityMap::Connection::IdentityMappable do
  describe "#get" do
    before do
      @model = Model.create(:name => 'get')
    end

    it "should check the identity map for the object" do
      ActiveRest::IdentityMap.should_receive(:fetch).with(@model.db_id)

      model = Model.find(@model.id)
    end

    it "should retrieve the object from the database if not in identity map" do
      ActiveRest::Connection.should_receive(:get_without_identity_map).with(@model.db_id, {})

      model = Model.find(@model.id)
    end

    it "should not hit the database if the object exists in the identity map" do
      ActiveRest::IdentityMap.set(@model.db_id, @model)

      ActiveRest::Connection.should_not_receive(:get_without_identity_map)

      model = Model.find(@model.id)
    end
  end

  describe "#update" do
    before do
      @model = Model.create(:name => 'update')
    end

    it "should remove object from identity map" do
      ActiveRest::IdentityMap.should_receive(:remove).with(@model.db_id)

      @model.name = 'updated'
      @model.save
    end

    it "should update the object in the database" do
      response = mock('Response')
      response.stub!(:success?).and_return('true')
      response.stub!(:body).and_return('{"version":"2","name":"updated"}')

      ActiveRest::Connection.stub!(:update_without_identity_map).and_return(response)
      ActiveRest::Connection.should_receive(:update_without_identity_map).with(@model.db_id, instance_of(String))

      @model.name = 'updated'
      @model.save
    end
  end

  describe "#destroy" do
    before do
      @model = Model.create(:name => 'destroy')
    end

    it "should remove object from identity map" do
      ActiveRest::IdentityMap.should_receive(:remove).with(@model.db_id)

      @model.destroy
    end

    it "should remove object from database" do
      response = mock('Response')
      response.stub!(:success?).and_return('true')

      ActiveRest::Connection.stub!(:destroy_without_identity_map).and_return(response)
      ActiveRest::Connection.should_receive(:destroy_without_identity_map).with(@model.db_id)

      @model.destroy
    end
  end

  describe "#multi_get" do
    before do
      @model = Model.create(:name => 'multi_get_one')
      @other_model = Model.create(:name => 'multi_get_two')
      @that_model = Model.create(:name => 'multi_get_three')
    end

    it "should check the identity map for the objects" do
      ActiveRest::IdentityMap.should_receive(:get).exactly(2).with(instance_of(String))
      model = Model.find([@model.id, @other_model.id])
    end

    it "should retrieve the objects from the database if not in identity map" do
      ActiveRest::Connection.stub!(:multi_get_without_identity_map).and_return([@model, @other_model])
      ActiveRest::Connection.should_receive(:multi_get_without_identity_map).with([@model.db_id, @other_model.db_id], { :collapse => true })

      model = Model.find([@model.id, @other_model.id])
    end

    it "should not hit the database if the object exists in the identity map" do
      ActiveRest::IdentityMap.set(@model.db_id, @model)
      ActiveRest::IdentityMap.set(@other_model.db_id, @other_model)

      ActiveRest::Connection.should_not_receive(:multi_get_without_identity_map)

      model = Model.find([@model.id, @other_model.id])
    end

    it "should hit the database for those objects that don't exist in the identity map and preserve order" do
      ActiveRest::IdentityMap.set(@model.db_id, @model)
      ActiveRest::IdentityMap.set(@other_model.db_id, @other_model)

      ActiveRest::Connection.stub!(:multi_get_without_identity_map).and_return([@that_model])
      ActiveRest::Connection.should_receive(:multi_get_without_identity_map).with([@that_model.db_id], { :collapse => true })

      ActiveRest::IdentityMap.should_receive(:set).with(@that_model.db_id, instance_of(Model))

      [@model, @that_model, @other_model] == Model.find([@model.id, @that_model.id, @other_model.id])
    end
  end
end
