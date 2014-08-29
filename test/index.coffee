crypto = require 'crypto'
_auth = require('../index')
should = require('chai').should()
fs = require 'fs'

db_init  = _auth.init
db_close = _auth.close
db_create  = _auth.create
db_auth    = _auth.authenticate
db_update  = _auth.update
db_del     = _auth.delete
#_auth.debug()


#TODO# Removed due to node.crypto issue
#__$Keys = crypto.getDiffieHellman('modp5')
#__$Keys.generateKeys()
#__$privkey = __$Keys.getPrivateKey('base64')

__$hashkey = crypto.randomBytes(32).toString('base64')


#TODO: beforeEach() afterEach() to build & tear down DB for each test


beforeEach( (done) ->
  #console.log "%%% beforeEach START %%%"
  db_close( (e) ->
    should.not.exist(e)
    arg = {}
    arg['hashkey'] = __$hashkey
    arg['path'] = ':memory:'
    arg['callback'] = (e) ->
      should.not.exist(e)
      c_arg = {}
      c_arg['username'] = 'foo'
      c_arg['userpass'] = 'bar'
      c_arg['callback'] = (e,r) ->
        should.not.exist(e)
        should.exist(r)
        r.should.equal(1) if r?
        #console.log "%%% beforeEach DONE %%%"
        done()
      db_create(c_arg)
    db_init(arg)
   )
 )

afterEach( (done) ->
  #console.log "%%% afterEach START %%%"
  db_close( (e) ->
    should.not.exist(e)
    #console.log "%%% afterEach DONE %%%"
    done()
    )
 )

describe( 'init() - {hashkey, path, [callback]}', () ->
  it( 'create :memory:', (done) ->
    db_close( (e) ->
      should.not.exist(e)
      # INIT DB
      arg = {}
      arg['hashkey'] = __$hashkey
      arg['path'] = ':memory:'
      arg['callback'] = (e) ->
        should.not.exist(e)
        done()
      db_init(arg)
      )
    ) # it end

  it( 'e: db exists error', (done) ->
    arg = {}
    arg['hashkey'] = __$hashkey
    arg['path'] = ':memory:'
    arg['callback'] = (e) ->
      e.should.equal('__Authdb already exists')
      done()
    db_init(arg)
    ) # it end
  ) # describe End

describe( 'close() - [callback]' , () ->
  it( 'db exists' , (done) ->
    db_close( (e) -> 
      should.not.exist(e)
      done()
      )
    ) # it end

  it( 'db not exists' , (done) ->
    db_close( (e) -> 
      db_close( (e) -> 
        should.not.exist(e)
        done()
        )
      )
    ) # it end
  ) # describe End

describe( 'create() - {username, userpass, [pubkey], [callback]}' , () ->
  it( 'create' , (done) ->
    arg = {}
    arg['username'] = 'newfoo'
    arg['userpass'] = 'newbar'
    arg['callback'] = (e,r) -> 
      should.not.exist(e)
      r.should.equal(2)
      done()
    db_create(arg)
    ) # it end

  it( 'e: exists' , (done) ->
    arg = {}
    arg['username'] = 'foo'
    arg['userpass'] = 'bar'
    arg['callback'] = (e,r) -> 
      e.should.equal('already exists')
      should.not.exist(r)
      done()
    db_create(arg)
    ) # it end

  it( 'e: no username' , (done) ->
    arg = {}
    #arg['username'] = 'foo'
    arg['userpass'] = 'bar'
    arg['callback'] = (e,r) -> 
      e.should.equal('create error')
      should.not.exist(r)
      done()
    db_create(arg)
    ) # it end

  it( 'e: no userpass' , (done) ->
    arg = {}
    arg['username'] = 'foo'
    #arg['userpass'] = 'bar'
    arg['callback'] = (e,r) -> 
      e.should.equal('create error')
      should.not.exist(r)
      done()
    db_create(arg)
    ) # it end
  ) # describe End

describe( 'authenticate() - {username, userpass, [callback]}' , () ->
  it( 'auth' , (done) ->
    arg = {}
    arg['username'] = 'foo'
    arg['userpass'] = 'bar'
    arg['callback'] = (e,r) ->
      should.not.exist(e)
      r.should.equal(1)
      done()
    db_auth(arg)
    ) # it end

  it( 'e: not exist' , (done) ->
    arg = {}
    arg['username'] = 'notfoo'
    arg['userpass'] = 'notbar'
    arg['callback'] = (e,r) ->
      done()
      e.should.equal('doesnt exist')
    db_auth(arg)
    ) # it end

  it( 'e: bad pass' , (done) ->
    arg = {}
    arg['username'] = 'foo'
    arg['userpass'] = 'badbar'
    arg['callback'] = (e,r) ->
      e.should.equal('bad password')
      done()
    db_auth(arg)
    ) # it end

  it( 'e: no username' , (done) ->
    arg = {}
    #arg['username'] = 'foo'
    arg['userpass'] = 'bar'
    arg['callback'] = (e,r) ->
      e.should.equal('auth error')
      done()
    db_auth(arg)
    ) # it end

  it( 'e: no userpass' , (done) ->
    arg = {}
    arg['username'] = 'foo'
    #arg['userpass'] = 'bar'
    arg['callback'] = (e,r) ->
      e.should.equal('auth error')
      done()
    db_auth(arg)
    ) # it end

  #it( '-TODO- e: deleted' , (done) ->
  #  arg = {}
  #  arg['username'] = 'foo'
  #  arg['userpass'] = 'bar'
  #  arg['callback'] = (e,r) -> 
  #    e.should.equal('create error')
  #    should.not.exist(r)
  #    done()
  #  db_create(arg)
  #  ) # it end
  ) # describe End

describe( 'update() - {userid, [username], [userpass], [pubkey], [perm], [isEnabled], [callback]}' , () ->
  it( 'updated' , (done) ->
    arg = {}
    arg['userid'] = 1
    arg['username'] = 'updatedfoo'
    arg['userpass'] = 'updatedbar'
    arg['pubkey'] = 'not implemented yet'
    arg['perm'] = 'not implemented yet'
    arg['isEnabled'] = 1
    arg['callback'] = (e,r) ->
      should.not.exist(e)
      r.should.equal(1)
      done()
    db_update(arg)
    ) # it end

  it( 'not exist' , (done) ->
    arg = {}
    arg['userid'] = 99
    arg['callback'] = (e,r) ->
      e.should.equal('doesnt exists')
      done()
    db_update(arg)
    ) # it end

  it( 'update error' , (done) ->
    arg = {}
    #arg['userid'] = 1
    arg['callback'] = (e,r) ->
      e.should.equal('update error')
      done()
    db_update(arg)
    ) # it end
  ) # describe End

describe( 'delete() - {userid, [callback]}' , () ->
  it( 'deleted' , (done) ->
    arg = {}
    arg['userid'] = 1
    arg['callback'] = (e,r) ->
      should.not.exist(e)
      r.should.equal(1)
      done()
    db_del(arg)
    ) # it end

  it( 'delete error' , (done) ->
    arg = {}
    #arg['userid'] = 1
    arg['callback'] = (e,r) ->
      e.should.equal('delete error')
      done()
    db_del(arg)
    ) # it end

  it( 'not exist' , (done) ->
    arg = {}
    arg['userid'] = 2
    arg['callback'] = (e,r) ->
      e.should.equal('doesnt exists')
      done()
    db_del(arg)
    ) # it end
  ) # describe End













