# ActiveRest Identity Map

ActiveRest Identity Map is either on or off; Enable by adding to Gemfile and disable by removing.
The included railtie automatically injects the identity into the pertinent call paths
and inserts middle to clear the identity map before each request.  It can also be manually
cleared by call `ActiveRest::IdentityMap.clear`.
