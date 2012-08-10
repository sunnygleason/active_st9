require "spec_helper"

describe ActiveRest::IdentityMap::ClearMiddleware do
  before do
    @env = {}
    @resp = stub("resp")
    @app = stub("app")
    @app.stub!(:call).with(@env).and_return(@resp)

    @clear_middleware = ActiveRest::IdentityMap::ClearMiddleware.new(@app)
  end

  it "should return app response" do
    @clear_middleware.call(@env).should be(@resp)
  end

  it "should clear identity map" do
    ActiveRest::IdentityMap.should_receive(:clear)

    @clear_middleware.call(@env)
  end
end
