_ = require("underscore")._
Rest = require("../lib/rest")
Config = require('../config').config.prod

describe "Rest", ->

  it "should initialize with default options", ->
    rest = new Rest
      config: Config
    expect(rest).toBeDefined()
    expect(rest._oauth).toBeDefined()
    expect(rest._options.host).toBe "api.sphere.io"
    expect(rest._options.access_token).not.toBeDefined()
    expect(rest._options.uri).toBe "https://api.sphere.io/#{Config.project_key}"
    expect(rest._options.timeout).toBe 20000
    expect(rest._options.rejectUnauthorized).toBe true
    expect(rest._options.headers["User-Agent"]).toBe "sphere-node-connect"
    expect(rest._options.verbose).toBe false

  it "should throw error if no credentials are given", ->
    rest = -> new Rest
    expect(rest).toThrow new Error("Missing credentials")

  _.each ["client_id", "client_secret", "project_key"], (key)->
    it "should throw error if no '#{key}' is defined", ->
      opt = _.clone(Config)
      delete opt[key]
      rest = -> new Rest config: opt
      expect(rest).toThrow new Error("Missing '#{key}'")

  it "should pass 'host' option", ->
    rest = new Rest
      config: Config
      host: "example.com"
    expect(rest._options.host).toBe "example.com"

  it "should pass 'access_token' option", ->
    rest = new Rest
      config: Config
      access_token: "qwerty"
    expect(rest._options.access_token).toBe "qwerty"

  it "should pass 'timeout' option", ->
    rest = new Rest
      config: Config
      timeout: 100
    expect(rest._options.timeout).toBe 100

  it "should pass 'rejectUnauthorized' option", ->
    rest = new Rest
      config: Config
      rejectUnauthorized: false
    expect(rest._options.rejectUnauthorized).toBe false

  it "should pass 'oauth_host' option", ->
    rest = new Rest
      config: Config
      oauth_host: "auth.escemo.com"
    expect(rest._oauth._options.host).toBe "auth.escemo.com"

  it "should pass 'user_agent' option", ->
    rest = new Rest
      config: Config
      user_agent: "commercetools"
    expect(rest._options.headers["User-Agent"]).toBe "commercetools"

  it "should pass 'verbose' option", ->
    rest = new Rest
      config: Config
      verbose: true
    expect(rest._options.verbose).toBe true

describe "Rest requests", ->

  beforeEach ->
    opts =
      config: Config
      access_token: "foo"
    @rest = new Rest opts

    spyOn(@rest, "_doRequest").andCallFake((options, callback)-> callback(null, null, {id: "123"}))
    spyOn(@rest._oauth, "getAccessToken").andCallFake((callback)-> callback(null, {statusCode: 200}, {access_token: "foo"}))

  afterEach ->
    @rest = null

  prepareRequest = (done, f)->
    callMe = (e, r, b)->
      expect(b.id).toBe "123"
      done()
    expected_options =
      uri: "https://api.sphere.io/#{Config.project_key}/product-projections"
      json: true
      method: "GET"
      headers:
        "User-Agent": "sphere-node-connect"
        "Authorization": "Bearer foo"
      timeout: 20000
      rejectUnauthorized: true
    f(callMe, expected_options)

  it "should send GET request", (done)->
    prepareRequest done, (callMe, expected_options)=>
      @rest.GET("/product-projections", callMe)
      expect(@rest._doRequest).toHaveBeenCalledWith(expected_options, jasmine.any(Function))

  it "should send GET request with OAuth", (done)->
    rest = new Rest config: Config
    spyOn(rest._oauth, "getAccessToken").andCallFake((callback)-> callback(null, {statusCode: 200}, {access_token: "foo"}))
    spyOn(rest, "_doRequest").andCallFake((options, callback)-> callback(null, null, {id: "123"}))
    prepareRequest done, (callMe, expected_options)->
      rest.GET("/product-projections", callMe)
      expect(rest._oauth.getAccessToken).toHaveBeenCalledWith(jasmine.any(Function))
      expect(rest._doRequest).toHaveBeenCalledWith(expected_options, jasmine.any(Function))

  it "should send POST request", (done)->
    prepareRequest done, (callMe, expected_options)=>
      @rest.POST("/products", {name: "Foo"}, callMe)
      _.extend expected_options,
        uri: "https://api.sphere.io/#{Config.project_key}/products"
        method: "POST"
        body: {name: "Foo"}
      expect(@rest._doRequest).toHaveBeenCalledWith(expected_options, jasmine.any(Function))

  it "should send POST request with OAuth", (done)->
    rest = new Rest config: Config
    spyOn(rest._oauth, "getAccessToken").andCallFake((callback)-> callback(null, {statusCode: 200}, {access_token: "foo"}))
    spyOn(rest, "_doRequest").andCallFake((options, callback)-> callback(null, null, {id: "123"}))
    prepareRequest done, (callMe, expected_options)->
      rest.POST("/products", {name: "Foo"}, callMe)
      _.extend expected_options,
        uri: "https://api.sphere.io/#{Config.project_key}/products"
        method: "POST"
        body: {name: "Foo"}
      expect(rest._oauth.getAccessToken).toHaveBeenCalledWith(jasmine.any(Function))
      expect(rest._doRequest).toHaveBeenCalledWith(expected_options, jasmine.any(Function))

  it "should fail to getting an access_token after 10 attempts", ->
    rest = new Rest config: Config
    spyOn(rest._oauth, "getAccessToken").andCallFake((callback)-> callback(null, {statusCode: 401}, null))
    req = -> rest._preRequest(rest._oauth, {}, {}, ->)
    expect(req).toThrow new Error "Could not retrieve access_token after 10 attempts.\n" +
      "Status code: 401\n" +
      "Body: null\n"

  it "should fail on error", ->
    rest = new Rest config: Config
    spyOn(rest._oauth, "getAccessToken").andCallFake((callback)-> callback("Connection read timeout", null, null))
    req = -> rest._preRequest(rest._oauth, {}, {}, ->)
    expect(req).toThrow new Error "Error on retrieving access_token after 10 attempts.\n" +
      "Error: Connection read timeout\n"

  it "should throw error for unimplented PUT request", ->
    rest = new Rest config: Config
    expect(rest.PUT).toThrow new Error "Not implemented yet"
