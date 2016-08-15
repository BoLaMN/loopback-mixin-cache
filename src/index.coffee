{ createHash } = require 'crypto'
{ isFunction } = require 'lodash'

module.exports = (Model, options) ->

  Model.on 'attached', (server) ->

    Model.beforeRemote '**', (context, unused, cb) ->
      { method, args, methodString } = context
      { cache } = Model.app

      key = methodString

      switch method.accessType
        when 'READ'
          if args?.filter?.where
            key += JSON.stringify args.filter.where

      context.keyCache = createHash 'md5'
        .update key
        .digest 'hex'

      cache.get context, cb

      return

    Model.afterRemote '**', (context, unused, cb) ->
      cb()

      { cache } = Model.app

      switch context.method.accessType
        when 'READ'
          cache.set context.keyCache, context.result

    return

  return
