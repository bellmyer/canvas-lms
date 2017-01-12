define [
  'compiled/models/ImageFile'
  'vendor/FileAPI/FileAPI.min'
], (ImageFile, FileAPI) ->

  model = null
  file = {}

  module 'ImageFile',
    setup: ->
      model = new ImageFile(null, preflightUrl: '/preflight')
      file = {}
      @stub FileAPI, 'getFiles', -> [file]
      @stub FileAPI, 'filterFiles', (f, cb) ->
        cb(file, file)

    teardown: ->

  test 'returns a useful deferred', ->
    file = {type: "text/plain", size: 1234}
    equal model.loadFile().state(), "rejected"
    file = {type: "image/foo", size: 1234}
    equal model.loadFile().state(), "rejected"
    file = {type: "image/png", size: 123546}
    equal model.loadFile().state(), "rejected"
    file = {type: "image/png", size: 12345}
    equal model.loadFile().state(), "rejected"
    file = {type: "image/png", size: 12345, width: 1000, height: 100}
    equal model.loadFile().state(), "rejected"
    file = {type: "image/png", size: 12345, width: 100, height: 100}
    equal model.loadFile().state(), "resolved"

