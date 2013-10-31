_ = require("underscore")._
request = require("request")
OAuth2 = require("./oauth2").OAuth2

exports.Rest = (opts = {})->
  throw new Error("Missing 'client_id'") unless opts.client_id
  throw new Error("Missing 'client_secret'") unless opts.client_secret
  throw new Error("Missing 'project_key'") unless opts.project_key

  @_options =
    config:
      client_id: opts.client_id
      client_secret: opts.client_secret
      project_key: opts.project_key
    host: opts.host or "api.sphere.io"

  _.extend @_options,
    request:
      uri: "https://#{@_options.host}/#{@_options.config.project_key}"
      timeout: 20000

  if @_options.access_token
    _.extend @_options.request,
      headers:
        "Authorization": "Bearer #{@_options.access_token}"
  @

exports.Rest.prototype.GET = (resource, callback)->
  params =
    resource: resource
    method: "GET"
  exports.preRequest(@_options, params, callback)

exports.Rest.prototype.POST = (resource, payload, callback)->
  params =
    resource: resource
    method: "POST"
    body: payload
  exports.preRequest(@_options, params, callback)

exports.Rest.prototype.PUT = -> #noop
exports.Rest.prototype.DELETE = -> #noop

exports.preRequest = (options, params, callback)->
  _req = ->
    unless options.access_token
      exports.doAuth options.config, (data)->
        access_token = data.access_token
        options.access_token = access_token
        _.extend options.request,
          headers:
            "Authorization": "Bearer #{access_token}"
        # call itself again (this time with the access_token)
        _req()
    else
      request_options = _.clone(options.request)
      _.extend request_options,
        uri: "#{request_options.uri}#{params.resource}"
        method: params.method
      if params.body
        request_options.body = params.body
      exports.doRequest(request_options, callback)
  _req()

exports.doRequest = (options, callback)->
  request options, (error, response, body)->
    callback(error, response, body)

exports.doAuth = (config = {}, callback)->
  oa = new OAuth2 config
  oa.getAccessToken (data)-> callback(data)