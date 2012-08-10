require "spec_helper"

describe ActiveRest::IdentityMap do
  let(:model) { Model.create(:name => 'model') }
  let(:other_model) { Model.create(:name => 'other_model') }
  let(:model_key) { model.db_id }
  let(:other_model_key) { other_model.db_id }

  describe "storage" do
    describe "in multiple threads" do
      it "should keep each thread's storage separate" do
        ActiveRest::IdentityMap.set(model_key, model)

        Thread.new do
          ActiveRest::IdentityMap.set(model_key, model)
          ActiveRest::IdentityMap.get(model_key).should == model
          ActiveRest::IdentityMap.remove(model_key)
        end.join

        ActiveRest::IdentityMap.get(model_key).should == model
      end
    end
  end

  describe ".fetch" do
    before do
      Model.stub!(:first).and_return(model)
    end

    let(:fetch) do
      ActiveRest::IdentityMap.fetch(model_key) do
        Model.first
      end
    end

    context "when model doesn't exist in identity map" do
      it "should store model in identity map" do
        fetch
        ActiveRest::IdentityMap.get(model_key).should be(model)
      end

      it "should return model" do
        fetch.should be(model)
      end
    end

    context "when model exists in identity map" do
      before do
        ActiveRest::IdentityMap.set(model_key, model)
      end

      it "should not yield block" do
        Model.should_not_receive(:first)
        fetch
      end

      it "should return model" do
        fetch.should be(model)
      end
    end
  end

  describe ".remove" do
    before do
      ActiveRest::IdentityMap.set(model_key, model)
    end

    it "should remove model from identity map" do
      ActiveRest::IdentityMap.remove(model_key)
      ActiveRest::IdentityMap.get(model_key).should be_nil
    end
  end

  describe ".clear" do
    before do
      ActiveRest::IdentityMap.set(model_key, model)
      ActiveRest::IdentityMap.set(other_model_key, other_model)
    end

    it "should clear identity map" do
      ActiveRest::IdentityMap.clear

      ActiveRest::IdentityMap.get(model_key).should be_nil
      ActiveRest::IdentityMap.get(other_model_key).should be_nil
    end
  end
end
