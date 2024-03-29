// Generated by CoffeeScript 1.6.2
exports.setEnvironment = function(env) {
  console.log("set app environment: " + env);
  switch (env) {
    case "development":
      exports.DEBUG_LOG = true;
      exports.DEBUG_WARN = true;
      exports.DEBUG_ERROR = true;
      return exports.DEBUG_CLIENT = true;
    case "testing":
      exports.DEBUG_LOG = true;
      exports.DEBUG_WARN = true;
      exports.DEBUG_ERROR = true;
      return exports.DEBUG_CLIENT = true;
    case "production":
      exports.DEBUG_LOG = false;
      exports.DEBUG_WARN = false;
      exports.DEBUG_ERROR = true;
      return exports.DEBUG_CLIENT = false;
    default:
      return console.log("environment " + env + " not found");
  }
};
