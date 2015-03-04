ca-auth
=======

<<<<<<< HEAD
**Simple Secure Auth Package**

=======
[![NPM](https://nodei.co/npm/ca-auth.png)](https://npmjs.org/package/ca-auth)

**Simple Secure Auth Package**

>>>>>>> 37ec222d39ee56e09dc5c4cf627b3a9ad5f21658
######
This Lib is the beginings of an Authentication framework.  It makes use of `crypto` and `sqlite3` to create, store, check hashed username / password combinations.  


##Install
`npm install ca-auth`


##API
> ca-auth.init(Args, Args.hashkey, Args.path, Args.callback) 
> -----------------------------
> Inits authentication database
> 
> **Parameters**
> 
> **Args**: object, **Only Real Param** All Other Params should be properties of `Args`
> 
> **Args.hashkey**: string, can be any string, *should* be random data with a lenght atleast as long as any password being hashed.  Must be the same Value between runs or hashes will not match
> 
> **Args.path**: string, *[optional]* path to sqlite3 database *if not set `_auth.db` in package root will be created / used*
> 
> **Args.callback**: function, *[optional]* called when DB is ready

&nbsp;

> ca-auth.close(callback) 
> -----------------------------
> Closes authentication database
> 
> **Parameters**
> 
> **callback**: function, *[optional]* called after db has ben closed

&nbsp;

> ca-auth.create(Args, Args.username, Args.userpass, Args.callback) 
> -----------------------------
> Creates User *fails if user already exists*
> 
> **Parameters**
> 
> **Args**: object, **Only Real Param** All Other Params should be properties of `Args`
> 
> **Args.username**: string, Username String *could also be hash*
> 
> **Args.userpass**: string, Password String *could also be hash*
> 
> **Args.callback**: function, *[optional]* will be passed `error`,`authID` **error** will be a `string` error string or `null`, **authID** will be a `null` or `int` users authID

&nbsp;

> ca-auth.authenticate(Args, Args.username, Args.userpass, Args.callback) 
> -----------------------------
> Authentication of users
> 
> **Parameters**
> 
> **Args**: object, **Only Real Param** All Other Params should be properties of `Args`
> 
> **Args.username**: string, Username String *could also be hash (must be same as what was used for `create`)*
> 
> **Args.userpass**: string, Password String *could also be hash (must be same as what was used for `create`)*
> 
> **Args.callback**: function, *[optional]* will be passed `error`,`authID` **error** will be a `string` error string or `null`, **authID** will be a `null` or `int` users authID

&nbsp;

> ca-auth.update(Args, Args.userid, Args.username, Args.userpass, Args.isEnabled, Args.callback) 
> -----------------------------
> Updates user data for a given userid *fails if user does not exist*
> 
> **Parameters**
> 
> **Args**: object, **Only Real Param** All Other Params should be properties of `Args`
> 
> **Args.userid**: int, authUID of the user to be updated
> 
> **Args.username**: string, *[optional]* Username String *could also be hash*
> 
> **Args.userpass**: string, *[optional]* Password String *could also be hash*
> 
> **Args.isEnabled**: int, *[optional]* can be 0 or 1
> 
> **Args.callback**: function, *[optional]* will be passed `error`,`authID` **error** will be a `string` error string or `null`, **authID** will be a `null` or `int` users authID

&nbsp;

> ca-auth.delete(Args, Args.userid, Args.callback) 
> -----------------------------
> Soft delete of user *changes isEnabled to 0 preventing Authentication*
> 
> **Parameters**
> 
> **Args**: object, **Only Real Param** All Other Params should be properties of `Args`
> 
> **Args.userid**: int, authUID of the user to be deleted
> 
> **Args.callback**: function, *[optional]* will be passed `error`,`authID` **error** will be a `string` error string or `null`, **authID** will be a `null` or `int` users authID

##TODO:
> **Coding:**
>
> **Testing / Doc:**
> - [x] Doc API
<<<<<<< HEAD
>
> **Eventualy:**
=======
> - [ ] Add Example Code
>
> **Eventualy:**
> - [ ] Change functions to take multiple Arguments instead of `Args` object
>>>>>>> 37ec222d39ee56e09dc5c4cf627b3a9ad5f21658
> - [ ] Implement Public Key Authentication
> - [ ] Update Tests to check for changes on DB side after command
> - [ ] Implement Permissions system
> - [ ] Implement Logging system


####Disclaimer:
This is a toy project, and should not be used for production grade anything ... use at your own risk
