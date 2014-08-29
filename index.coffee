sqlite3 = require('sqlite3') #.verbose()
events = require 'events'

## Crypto Lib ######################################################################
## node-forge ------------------------------------------------------------------TODO
# crypto = require 'node-forge' # 
# npm install node-forge
# - https://github.com/digitalbazaar/forge
# - TODO: https://github.com/digitalbazaar/forge#rsa

## sjcl ----------------------------------------------------------------------------
# crypto = require 'sjcl' # Stanford javascript crypto library
# npm install sjcl
# - https://github.com/bitwiseshiftleft/sjcl
# - http://bitwiseshiftleft.github.io/sjcl/doc/

## crypto --------------------------------------------------------------------------
crypto = require 'crypto' # Built in Node.js Encryption Lib
# - issue - Loading Private Key currently not working

## crypto-js -----------------------------------------------------------------------
# crypto = require 'crypto-js' # Modularized port of googlecode project crypto-js.
# npm install crypto-js
# - https://github.com/evanvosberg/crypto-js
# - https://code.google.com/p/crypto-js/
# - issue - Does not Support PKI

__HashKey = null

#TODO# Removed due to node.crypto issue
#__PrivKey = crypto.getDiffieHellman('modp5')

__dbg = false
__Authdb = null
__dbready = false
__dbreadyque = []

# {authUID, authNameHash, authPubKey, authPWHash, authPWSalt, authPerm, isEnabled}
__Auth_tbl =  "CREATE TABLE IF NOT EXISTS _auth ("
__Auth_tbl += " authUID INTEGER PRIMARY KEY,"    # UID - Primary Key
__Auth_tbl += " authNameHash TEXT,"              # Hash of UserName + Key
__Auth_tbl += " authPubKey TEXT,"                # Public Key 'base64'
__Auth_tbl += " authPWHash TEXT,"                # Hash of Password + Salt + Key
__Auth_tbl += " authPWSalt TEXT,"                # Salt
__Auth_tbl += " authPerm TEXT,"                  # List of Groups
__Auth_tbl += " isEnabled INTEGER"               # Soft Delete
__Auth_tbl += " )"

# {eventUID, TimeStamp, eventType, eventDetails }
__Log_tbl =  "CREATE TABLE IF NOT EXISTS _log ("
__Log_tbl += "eventUID INTEGER PRIMARY KEY, "
__Log_tbl += "TimeStamp TEXT NOT NULL, "
__Log_tbl += "eventType TEXT NOT NULL, "
__Log_tbl += "eventDetails TEXT NOT NULL"
__Log_tbl += " )"

__Encrypt = (aMsg,aSecret) ->
  console.log '__Encrypt' if __dbg
  cipher = crypto.createCipher('aes-256-cbc', aSecret)
  cipher.update(aMsg, 'utf8', 'base64')
  return cipher.final('base64')

__Decrypt = (aMsg,aSecret) ->
  console.log '__Decrypt' if __dbg
  decipher = crypto.createDecipher('aes-256-cbc', aSecret)
  decipher.update(aMsg.replace(/\s/g, "+"), 'base64', 'utf8')
  return decipher.final('utf8')

__Hash = (aValue,aKey,aSalt) ->
  console.log '__Hash' if __dbg
  tHash = crypto.createHmac('sha256', aKey )
  tHash.update(aValue) if aValue?
  tHash.update(aSalt) if aSalt?
  return tHash.digest('base64')

__initdb = (aOpt) ->
  console.log '__initdb' if __dbg
  if __Authdb?
    aOpt.callback('__Authdb already exists') if aOpt.callback?
    return
  __HashKey = aOpt.hashkey #if aOpt? && aOpt.hashkey?
  #TODO# Removed due to node.crypto issue
  #__PrivKey.setPrivateKey(aOpt.privkey,'base64') #if aOpt? && aOpt.privkey?
  dbpath = aOpt.path if aOpt? && aOpt.path?
  dbpath ?= "_auth.db" if __dbg
  __dbreadyque.push(aOpt.callback) if aOpt.callback?
  # Init DB
  __Authdb = new sqlite3.Database(dbpath, () -> 
    console.log 'db created' if __dbg
    # create _auth
    __Authdb.run(__Auth_tbl,() ->
      console.log ' - tbl _auth created' if __dbg
      # create _log
      __Authdb.run(__Log_tbl, () ->
        console.log ' - tbl _log created' if __dbg
        # process que
        __dbready = true
        for fn in __dbreadyque
          fn()
        return
      )
      return
    )
    return
  )
  return

__prune = (aObj, aList) ->
  console.log '__prune' if __dbg
  tRet = {}
  for k, v of aObj
    tRet[k] = v if k in aList
  return tRet
  
  #http://www.youtube.com/watch?v=AO5Ns-dz-s0

__create = (aOpt) ->
  console.log '__create' if __dbg
  tOpt = __prune(aOpt,['username','userpass','pubkey','callback'])
  #TODO# Removed due to node.crypto issue
  #if not tOpt.username? || not (tOpt.userpass? || tOpt.pubkey?)
  if not tOpt.username? || not tOpt.userpass? 
    tOpt.callback('create error') if tOpt.callback?
    return
  #TODO# Removed due to node.crypto issue
  #if not tOpt.userpass?
  #  tOpt.userpass = crypto.randomBytes(32).toString('base64')
  oAuth = new __objAuth(tOpt)
  oAuth._find()
  oAuth.on('updated', () =>
    oAuth._respondOnce(null, oAuth.PostQuery.authUID )
    return
    )
  oAuth.on('error', () =>
    oAuth._respondOnce('gen error')
    return
    )
  oAuth.on('does_exists', () =>
    oAuth._respondOnce('already exists')
    return
    )
  oAuth.on('doesnt_exist', () =>
    oAuth._update()
    return
    )
  return

__authenticate = (aOpt) ->
  console.log '__authenticate' if __dbg
  #TODO# Removed due to node.crypto issue
  #tOpt = __prune(aOpt,['username','userpass','keychal','keyresp','callback'])
  tOpt = __prune(aOpt,['username','userpass','callback'])
  if not tOpt.username? || not ( tOpt.userpass? || (tOpt.keychal? && tOpt.keyresp?))
    tOpt.callback('auth error') if tOpt.callback?
    return
  oAuth = new __objAuth(tOpt)
  oAuth._find()
  oAuth.on('does_exists', () =>
    #TODO# Removed due to node.crypto issue
    #if tOpt.keychal? && tOpt.keyresp? # Pub Key Auth
    #  tChallenge = oAuth.PreQuery.keychal  # crypto.randomBytes(32).toString('base64')
    #  encResponce = oAuth.PreQuery.keyresp # __Encrypt(tChallenge,tSecret)
    #  tPubKey = oAuth.PostQuery.authPubKey # users public key
    #  tSecret = __PrivKey.computeSecret( tPubKey, 'base64','base64')
    #  tResponce = __Decrypt(encResponce,tSecret)
    #  if tResponce == tChallenge
    #    oAuth._respondOnce(null,oAuth.PostQuery.authUID)
    #    return
    #  else
    #    oAuth._respondOnce('bad challenge/responce')
    #    return
    #  return
    #else
    if true  #TODO# Added due to node.crypto issue
      tSalt = oAuth.PostQuery.authPWSalt
      tHash = oAuth.PostQuery.authPWHash
      tTest = __Hash(oAuth.PreQuery.userpass,__HashKey,tSalt)
      if  tTest == tHash && oAuth.PostQuery.isEnabled is 1
        oAuth._respondOnce(null,oAuth.PostQuery.authUID)
      else
        oAuth._respondOnce('bad password')
      return
    return
    )
  oAuth.on('doesnt_exist', () =>
    oAuth._respondOnce('doesnt exist')
    return
    )
  return

__update = (aOpt) ->
  console.log '__update' if __dbg
  tOpt = __prune(aOpt,['userid','username','userpass','pubkey','perm', 'isEnabled','callback'])
  if not tOpt.userid?
    tOpt.callback('update error') if tOpt.callback?
    return
  oAuth = new __objAuth(tOpt)
  oAuth._find()
  oAuth.on('updated', () =>
    oAuth._respondOnce(null, oAuth.PostQuery.authUID)
    return
    )
  oAuth.on('error', () =>
    oAuth._respondOnce('gen error')
    return
    )
  oAuth.on('does_exists', () =>
    oAuth._update()
    return
    )
  oAuth.on('doesnt_exist', () =>
    oAuth._respondOnce('doesnt exists')
    return
    )
  return

__delete = (aOpt) ->
  console.log '__delete' if __dbg
  tOpt = __prune(aOpt,['userid','callback'])
  if not tOpt.userid?
    tOpt.callback('delete error') if tOpt.callback?
    return
  tOpt.isEnabled = 0
  oAuth = new __objAuth(tOpt)
  oAuth._find()
  oAuth.on('updated', () =>
    oAuth._respondOnce(null, oAuth.PostQuery.authUID)
    return
    )
  oAuth.on('error', () =>
    oAuth._respondOnce('gen error')
    return
    )
  oAuth.on('does_exists', () =>
    oAuth._update()
    return
    )
  oAuth.on('doesnt_exist', () =>
    oAuth._respondOnce('doesnt exists')
    return
    )
  return

class __objAuth
  constructor: (aOpt) ->
    events.EventEmitter.call this
    _error = null
    _updating = false
    @PreQuery =
      source: null    # Request Source for Logging
      userid: null    # UserID
      username: null  # User Name
      userpass: null  # User Password
      keychal: null   # Pub Key Auth Challenge
      keyresp: null   # Pub Key Auth Responce
      pubkey: null    # User Public Key
      callback: null  # callback function
      perm: null      # permissions
      isEnabled: null # is user account enabled
    @PostQuery = 
      authUID: null
      authNameHash: null
      authPWHash: null
      authPubKey: null
      authPWSalt: null
      authPerm: null
      isEnabled: null
    @taskQue = []
    if aOpt?
      for k, v of aOpt
        @PreQuery[k] = v
    @_respondOnce = (e,r) =>
      @PreQuery.callback(e,r) if @PreQuery.callback?
      @PreQuery.callback = null
      clearTimeout(@selfDestruct)
    # Self destruct in 2s?
    @selfDestruct = setTimeout( @destroy, 2000 )

  destroy: () ->
    @_respondOnce('self destruct')
    @.removeAllListeners()

  _update: () ->
    console.log '_update' if __dbg
    sql_callback = (e,r) =>
      if e?
        @_error = e
        @emit 'error'
        @emit '_update_error'
        return
      @_updating = true
      @_find()
      #@emit 'updated'
      return
    # REPLACE INTO _auth
    tFill = {}
    tFill.$authNameHash = __Hash(@PreQuery.username, __HashKey) if @PreQuery.username?
    if @PreQuery.userpass?
      tFill.$authPWSalt = crypto.randomBytes(32).toString('base64')
      tFill.$authPWHash = __Hash(@PreQuery.userpass, __HashKey, tFill.$authPWSalt)
    tFill.$authPubKey = @PreQuery.pubkey
    tFill.$authPerm = @PreQuery.perm if @PreQuery.authPerm?
    tFill.$isEnabled = @PreQuery.isEnabled if @PreQuery.isEnabled?
    tFill.$authNameHash ?= @PostQuery.authNameHash
    tFill.$authPubKey ?= @PostQuery.authPubKey || ""
    tFill.$authPWSalt ?= @PostQuery.authPWSalt
    tFill.$authPWHash ?= @PostQuery.authPWHash
    tFill.$authPerm ?= @PostQuery.authPerm || ""
    tFill.$isEnabled = @PreQuery.isEnabled if @PreQuery.isEnabled?
    tFill.$isEnabled ?= @PostQuery.isEnabled if @PostQuery.isEnabled?
    tFill.$isEnabled ?= 1
    if @authUID?
      tFill.$authUID = @authUID if @authUID?
      tCol = "authUID,"
      tVal = "$authUID,"
    else
      tCol = ""
      tVal = ""
    tStmt = "REPLACE INTO _auth (#{tCol}authNameHash,authPubKey,authPWHash,authPWSalt,authPerm,isEnabled) "
    tStmt += "VALUES (#{tVal}$authNameHash,$authPubKey,$authPWHash,$authPWSalt,$authPerm,$isEnabled) "
    __Authdb.run( tStmt, tFill, sql_callback)
    return

  _find: () ->
    console.log '_find' if __dbg
    sql_callback = (e,r) =>
      if e?
        console.log e if __dbg
        @_error = e
        @emit 'error'
        @emit '_find_error'
        return
      @_populate(r)
    # SELECT * FROM _auth
    if @PreQuery.userid?
      __Authdb.get(" SELECT * FROM _auth WHERE authUID = ?",@PreQuery.userid, sql_callback)
      return
    if @PreQuery.username?
      tNameHash = __Hash(@PreQuery.username,__HashKey)
      __Authdb.get(" SELECT * FROM _auth WHERE authNameHash = ?",tNameHash, sql_callback)
      return
    @emit 'error'
    @emit '_find_error'
    return

  _populate: (r) ->
    console.log '_populate' if __dbg
    if r?
      #populate @PostQuery
      @PostQuery.authUID      = r.authUID
      @PostQuery.authNameHash = r.authNameHash
      @PostQuery.authPWHash   = r.authPWHash
      @PostQuery.authPubKey   = r.authPubKey
      @PostQuery.authPWSalt   = r.authPWSalt
      @PostQuery.authPerm     = r.authPerm
      @PostQuery.isEnabled    = r.isEnabled
      if not @_updating
        @emit 'does_exists'
      else
        @_updating = false
        @emit 'updated'
    else
      @emit 'doesnt_exist'
    return

__objAuth::__proto__ = events.EventEmitter::

module.exports = 
  init: (aOpt) ->
    __initdb(aOpt)
    return

  close: (aFn) ->
    nullit = (e) =>
      __Authdb = null
      __dbready = false
      __dbreadyque = []
      aFn(e) if aFn?
      return
    if __Authdb?
      __Authdb.close(nullit)
    else
      aFn() if aFn?
    return

  debug: () ->
    __dbg = true
    return

  create: (aOpt) ->
    if not __dbready
      __dbreadyque.push( () => __create(aOpt) )
      return
    __create(aOpt)
    return

  authenticate: (aOpt) ->
    if not __dbready
      __dbreadyque.push( () => __authenticate(aOpt) )
      return
    __authenticate(aOpt)
    return

  update: (aOpt) ->
    if not __dbready
      __dbreadyque.push( () => __update(aOpt) )
      return
    __update(aOpt)
    return

  delete: (aOpt) ->
    if not __dbready
      __dbreadyque.push( () => __delete(aOpt) )
      return
    __delete(aOpt)
    return
