sqlite3 = require('sqlite3') #.verbose()
crypto = require 'crypto'

__HashKey =  " This Key Should really be set on init "
__HashKey += " I could generate at random on run but "
__HashKey += " then old databases wouldnt work right "

__Authdb = null

init = (aOpt) ->
  if aOpt? 
    if aOpt.key?
      __HashKey = aOpt.key
    if aOpt.path?
      __Authdb = new sqlite3.Database(aOpt.path)
  else
    __Authdb = new sqlite3.Database("_auth.db")
  # Create Table ------------------------------------------------------
  # {authUID, authNameHash, authPWHash, authPWSalt, authPerm, isEnabled}
  tStmt =  "CREATE TABLE IF NOT EXISTS _auth ("
  tStmt += " authUID INTEGER PRIMARY KEY,"    # UID - Primary Key
  tStmt += " authNameHash TEXT,"              # Hash of UserName + Key
  tStmt += " authPWHash TEXT,"                # Hash of Password + Salt + Key
  tStmt += " authPWSalt TEXT,"                # Salt
  tStmt += " authPerm TEXT,"                  # List of Groups
  tStmt += " isEnabled INTEGER"               # Soft Delete
  tStmt += " )"
  cb = aOpt.callback 
  __Authdb.run(tStmt, cb)

__Hash = (aValue,aKey,aSalt) ->
  tHash = crypto.createHmac('sha256', aKey )
  tHash.update(aValue) if aValue?
  tHash.update(aSalt) if aSalt?
  return tHash.digest('base64')

class objAuth
  constructor: () ->
    #dbg# console.log "constructor"
    @objLocked = 0
    @taskQue = []
    @exists = 0 # doesnt < 0 < does

  _next: () =>
    #dbg# console.log "_next"
    tFn = @taskQue.shift()
    tFn() if tFn?

  # Waits for Responce
  authenticate: (aOpt) =>
    #dbg# console.log "authenticate"
    tOpt = {}
    for k,v of aOpt
      tOpt[k] = v if k in ['authName','authPW','callback']
    if not @args?
      if not aOpt.authName?
        aOpt.callback('no name') if aOpt.callback?
        return
      if not aOpt.authPW?
        aOpt.callback('no pass') if aOpt.callback?
        return
      @taskQue.push(@authenticate)
      @_find(tOpt)
      return
    tNameHash = __Hash(@args.authName, __HashKey)
    tPWHash = __Hash(@args.authPW, __HashKey, @authPWSalt)
    if @exists == -1
      @args.callback("not exist") if @args.callback?
      return
    if @isEnabled != 1 && @args.callback?
      @args.callback("disabled") if @args.callback?
      return
    if @authPWHash != tPWHash && @args.callback?
      @args.callback("bad pass")
      return
    if @authPWHash == tPWHash && @args.callback?
      @args.callback(@authUID) if @args.callback?
      return
    @args.callback("auth error") if @args.callback?

  create: (aOpt) =>
    #dbg# console.log "create"
    tOpt = {}
    for k,v of aOpt
      tOpt[k] = v if k in ['authName','authPW','callback']
    if not @args?
      if not tOpt.authName? || not tOpt.authPW?
        tOpt.callback("create error") if tOpt.callback?
        return
      @taskQue.push(@create)
      @_find(tOpt)
      return
    if @exists == -1
      @_update()
      @args.callback("created") if @args.callback?
      return
    if @exists == 1
      @args.callback("exists") if @args.callback?
      return
    @args.callback("create error") if @args.callback?
    return

  update: (aOpt) =>
    #dbg# console.log "update"
    tOpt = {}
    for k,v of aOpt
      tOpt[k] = v if k in ['authUID','authName','authPW','authPerm', 'isEnabled','callback']
    if not @args?
      @taskQue.push(@update)
      @_find(tOpt)
      return
    if @exists == -1
      @args.callback("not exist") if @args.callback?
      return
    if @exists == 1
      @_update()
      @args.callback("updated") if @args.callback?
      return
    @args.callback("update error") if @args.callback?
    return

  delete: (aOpt) =>
    #dbg# console.log "delete"
    tOpt = {}
    for k,v of aOpt
      tOpt[k] = v if k in ['authUID','callback']
    if not @args?
      @taskQue.push(@delete)
      @_find(aOpt)
      return
    if @exists == -1
      @args.callback("not exist") if @args.callback?
      return
    if @exists == 1
      @isEnabled = 0
      @_update()
      return
    @args.callback("delete error") if @args.callback?
    return

  _find: (aOpt) =>
    #dbg# console.log "_find"
    if aOpt?
      @objLocked = 1
      @args = aOpt
      if aOpt.authUID?
        __Authdb.get(" SELECT * FROM _auth WHERE authUID = ?",aOpt.authUID, @_populate)
        return
      if aOpt.authName? or aOpt.authNameHash?
        tNameHash = aOpt.authNameHash
        tNameHash ?= __Hash(aOpt.authName,__HashKey)
        __Authdb.get(" SELECT * FROM _auth WHERE authNameHash = ?",tNameHash, @_populate)
        return
    @args.callback("_find error") if @args.callback?
    return

  _update: () =>
    #dbg# console.log "_update"
    tFill = {}
    tFill.$authNameHash = __Hash(@args.authName, __HashKey) if @args.authName?
    if @args.authPW?
      tFill.$authPWSalt = crypto.randomBytes(32).toString('base64')
      tFill.$authPWHash = __Hash(@args.authPW, __HashKey, tFill.$authPWSalt)
    tFill.$authPerm = @args.authPerm if @args.authPerm?
    tFill.$isEnabled = @args.isEnabled if @args.isEnabled?
    tFill.$authNameHash ?= @authNameHash
    tFill.$authPWSalt ?= @authPWSalt
    tFill.$authPWHash ?= @authPWHash
    tFill.$authPerm ?= @authPerm || ""
    tFill.$isEnabled ?= @isEnabled if @isEnabled?
    tFill.$isEnabled ?= 1
    if not tFill.$authNameHash? && tFill.$authPWSalt? && tFill.$authPWHash?
      @args.callback() if @args.callback?
      return
    if @authUID?
      tFill.$authUID = @authUID if @authUID?
      tCol = "authUID,"
      tVal = "$authUID,"
    else
      tCol = ""
      tVal = ""
    tStmt = "REPLACE INTO _auth (#{tCol}authNameHash,authPWHash,authPWSalt,authPerm,isEnabled) "
    tStmt += "VALUES (#{tVal}$authNameHash,$authPWHash,$authPWSalt,$authPerm,$isEnabled) "
    tOpt = 
      authNameHash:tFill.$authNameHash
      callback: @args.callback
    __Authdb.run( tStmt, tFill, (e,r) => 
      #dbg# console.log tFill
      #dbg# console.log tStmt
      #dbg# console.log "_updating #{e || 'No Error'}"
      @_find( tOpt ))
    return

  _populate: (e,r) =>
    #dbg# console.log "_populate #{e},#{r}"
    if e?
      #TODO @args.callback if @args.callback?
      #dbg# console.log e
      @args.callback(e)
      return
    if r?
      @exists = 1
      @authUID      = r.authUID
      @authNameHash = r.authNameHash
      @authPWHash   = r.authPWHash
      @authPWSalt   = r.authPWSalt
      @authPerm     = r.authPerm
      @isEnabled    = r.isEnabled
    else
      @exists = -1
    @objLocked = 0
    @_next()
    return

module.exports = 
  init: (aOpt) ->
    init(aOpt)
  dbclose: () ->
    __Authdb.close()
  create: (aOpt) ->
    tAO = new objAuth()
    tAO.create(aOpt)
  authenticate: (aOpt) ->
    tAO = new objAuth()
    tAO.authenticate(aOpt)
  update: (aOpt) ->
    tAO = new objAuth()
    tAO.update(aOpt)
  delete: (aOpt) ->
    tAO = new objAuth()
    tAO.delete(aOpt)


