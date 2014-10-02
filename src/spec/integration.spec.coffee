_ = require 'underscore'
Config = require('../config').config
OAuth2 = require '../lib/oauth2'
Rest = require '../lib/rest'

_.each ['valid-ssl', 'self-signed-ssl'], (mode) ->
  isSelfSigned = mode is 'self-signed-ssl'

  xdescribe "Integration test (#{mode})", ->

    beforeEach ->
      if isSelfSigned
        @oa = new OAuth2
          config: Config.staging
          host: Config.staging.oauth_host
          rejectUnauthorized: false
        @rest = new Rest
          config: Config.staging
          host: Config.staging.api_host
          oauth_host: Config.staging.oauth_host
          rejectUnauthorized: false
      else
        @oa = new OAuth2
          config: Config.prod
        @rest = new Rest
          config: Config.prod
      @rest.logger.info = -> # don't print to console
      @rest.logger.warn = -> # don't print to console
      @rest._oauth.logger.info = -> # don't print to console
      @oa.logger.info = -> # don't print to console

    afterEach ->
      @oa = null
      @rest = null

    it 'should get access token', (done) ->
      @oa.getAccessToken (error, response, body) ->
        # as jasmine does not stop on the first failing expectation, we use an if here to distingush good and bad case
        if error
          # We don't want any error!
          expect(error).toBeUndefined()
          # This allows us to check the error case when we eg. use a wrong oauth host name
        else
          expect(body.access_token).toBeDefined()
        done()

    it 'should get products', (done) ->
      @rest.GET '/products', (error, response, body) ->
        expect(response.statusCode).toBe 200
        expect(body).toBeDefined()
        results = body.results
        expect(results.length).toBeGreaterThan 0
        expect(results[0].id).toEqual jasmine.any(String)
        done()

    it 'should return 404 if product is not found', (done) ->
      @rest.GET '/products/123', (error, response, body) ->
        expect(response.statusCode).toBe 404
        done()

    it 'should create an delete custom object', (done) ->
      data =
        container: 'integration'
        key: 'foo'
        value: 'bar'
      payload = JSON.stringify(data)
      @rest.POST '/custom-objects', payload, (error, response, body) =>
        expect(response.statusCode).toBe 201
        @rest.DELETE '/custom-objects/integration/foo', (error, response, body) ->
          expect(response.statusCode).toBe 200
          done()
