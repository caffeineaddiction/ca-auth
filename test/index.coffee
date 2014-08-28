_auth = require('../index')
should = require('chai').should()
fs = require 'fs'

init    = _auth.init
dbclose = _auth.dbclose
create  = _auth.create
auth    = _auth.authenticate
update  = _auth.update
del     = _auth.delete


#TODO: beforeEach() afterEach() to build & tear down DB for each test

beforeEach( () -> 
  # Slows down testing enough for db to react
  process.stdout.write('')
  )

describe('init {key, path, callback}', () ->
  it( 'creates :memory:', (done)->
    arg = {}
    arg.path = ':memory:'
    arg['callback'] = (e) ->
      should.not.exist(e)
      done()
    init(arg)
    )
  )

describe('create {authName, authPW}', () ->
  it( 'created', (done) ->
    init({path:':memory:',callback: () ->
      arg = {}
      arg['authName']  = 'Name'
      arg['authPW']    = 'Pass'
      arg['callback']  = (r) -> 
        r.should.equal('created')
        done()
      create(arg)
      })
    )

  it( 'no name', (done) ->
    init({path:':memory:',callback: () ->
      arg = {}
      # arg['authName']  = 'Name'
      arg['authPW']    = 'Pass'
      arg['callback']  = (r) -> 
        r.should.equal('create error')
        #r.should.equal('foobar') 
        done()
      create(arg)
      })
    )

  it( 'no pass', (done) ->
    init({path:':memory:',callback: () ->
      arg = {}
      arg['authName']  = 'Name'
      # arg['authPW']    = 'Pass'
      arg['callback']  = (r) -> 
        r.should.equal('create error')
        done()
      create(arg)
      })
    )

  it( 'exists', (done) ->
    init({path:':memory:',callback: () ->
      arg = {}
      arg['authName']  = 'Name'
      arg['authPW']    = 'Pass'
      arg['callback']  = (r) -> 
        arg = {}
        arg['authName']  = 'Name'
        arg['authPW']    = 'Pass'
        arg['callback']  = (r) -> 
          r.should.equal('exists')
          done()
        create(arg)
      create(arg)
      })
    )
  )

describe('auth {authName, authPW, callback}', () ->
  it( 'authed', (done) -> 
    init({path:':memory:',callback: () ->
      create({authName:'foo',authPW:'bar',callback: () ->
        arg = {}
        arg['authName']  = 'foo'
        arg['authPW']    = 'bar'
        arg['callback']  = (r) -> 
          r.should.equal(1)
          done()
        auth(arg)
      })
    })
  )

  it( 'no name', (done) -> 
    init({path:':memory:',callback: () ->
      create({authName:'foo',authPW:'bar',callback: () ->
        arg = {}
        # arg['authName']  = 'foo'
        arg['authPW']    = 'bar'
        arg['callback']  = (r) -> 
          r.should.equal('no name')
          done()
        auth(arg)
      })
    })
  )

  it( 'no pass', (done) -> 
    init({path:':memory:',callback: () ->
      create({authName:'foo',authPW:'bar',callback: () ->
        arg = {}
        arg['authName']  = 'foo'
        # arg['authPW']    = 'bar'
        arg['callback']  = (r) -> 
          r.should.equal('no pass')
          done()
        auth(arg)
      })
    })
  )

  it( 'not exist', (done) -> 
    init({path:':memory:',callback: () ->
      create({authName:'foo',authPW:'bar',callback: () ->
        arg = {}
        arg['authName']  = 'not foo'
        arg['authPW']    = 'bar'
        arg['callback']  = (r) -> 
          r.should.equal('not exist')
          done()
        auth(arg)
      })
    })
  )

  it( 'bad pass', (done) -> 
    init({path:':memory:',callback: () ->
      create({authName:'foo',authPW:'bar',callback: () ->
        arg = {}
        arg['authName']  = 'foo'
        arg['authPW']    = 'not bar'
        arg['callback']  = (r) -> 
          r.should.equal('bad pass')
          done()
        auth(arg)
      })
    })
  )

  it( 'disabled', (done) -> 
    init({path:':memory:',callback: () ->
      create({authName:'foo',authPW:'bar',callback: () ->
        update({authUID:1, isEnabled:0,callback: () ->
          arg = {}
          arg['authName']  = 'foo'
          arg['authPW']    = 'bar'
          arg['callback']  = (r) -> 
            r.should.equal('disabled')
            done()
          auth(arg)
        })
      })
    })
  ))

describe('update {authUID, authName, authPW, authPerm, isEnabled, callback}', () ->
  it( 'updated', (done) ->
    init({path:':memory:',callback: () ->
      create({authName:'foo',authPW:'bar',callback: () ->
        arg = {}
        arg['authName']  = 'foo'
        arg['authPW']    = 'newbar'
        arg['callback']  = (r) -> 
          r.should.equal('updated')
          done()
        update(arg)
      })
    })
  )

  it( 'not exist', (done) ->
    init({path:':memory:',callback: () ->
      create({authName:'foo',authPW:'bar',callback: () ->
        arg = {}
        arg['authName']  = 'notfoo'
        arg['authPW']    = 'bar'
        arg['callback']  = (r) -> 
          r.should.equal('not exist')
          done()
        update(arg)
      })
    })
  )

  it( 'update error', (done) ->
    init({path:':memory:',callback: () ->
      create({authName:'foo',authPW:'bar',callback: () ->
        arg = {}
        #arg['authName']  = 'foo'
        arg['authPW']    = 'bar'
        arg['callback']  = (r) -> 
          r.should.equal('_find error')
          done()
        update(arg)
      })
    })
  )
  )

describe('del {authUID, callback}', () ->
  it( 'deleted', (done) ->
    init({path:':memory:',callback: () ->
      create({authName:'foo',authPW:'bar',callback: () ->
        arg = {}
        arg.authUID = 1
        arg['callback']  = (r) -> 
          r.should.equal('updated')
          done()
        update(arg)
      })
    })
  )

  it( 'not exist', (done) ->
    init({path:':memory:',callback: () ->
      create({authName:'foo',authPW:'bar',callback: () ->
        arg = {}
        arg.authUID = -1
        arg['callback']  = (r) -> 
          r.should.equal('not exist')
          done()
        update(arg)
      })
    })
  )
  
  )















