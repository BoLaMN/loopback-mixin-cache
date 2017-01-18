{ createHash } = require 'crypto'
{ isFunction } = require 'lodash'

util = require 'util'
debug = require('debug')('loopback:mixins:cache')

module.exports = (Model, options) ->

  Model.observe 'before execute', (ctx, next) ->
    debug 'cache before execute', ctx

    { req, model } = ctx
    { params, command } = req
    { where, data, options } = params

    { cache } = Model.app

    if command in [ 'find', 'findOne', 'findById' ]
      key = model + ':' + JSON.stringify params or {}

      key = ctx.hookState.key = createHash 'md5'
        .update key
        .digest 'hex'

      debug 'getting cache with', util.inspect(ctx, false, null)

      cache.get key, (err, result) ->
        if err
          return next()

        if not result
          return next null, ctx

        ctx.hookState.cached = not not result
        ctx.res = result

        debug 'found cached result', result

        next()

    else next()

    return

  Model.observe 'after execute', (ctx, next) ->
    debug 'cache after execute', ctx

    next()

    if ctx.hookState.cached
      return

    { req, res, model, hookState } = ctx
    { params, command } = req
    { where, data, options } = params
    { cache } = Model.app
    { key } = hookState

    if command in [ 'find', 'findOne', 'findById' ]
      debug 'setting cache with', ctx

      cache.set key, res

  return

