express = require 'express'
http = require 'http'
path = require 'path'
less = require 'less-middleware'
nunjucks = require 'nunjucks'
wepay = require('wepay').WEPAY


wepay_settings = {
    'client_id'     : '127580',
    'client_secret' : '6180c3de46',
    'access_token'  : 'a9ff4ce866893119097e0c29ee1f7886b3891e76b4599ab589c232b4f2f6ddcd', // used for oAuth2
}


app = express()

app.configure ->
  env = new nunjucks.Environment(new nunjucks.FileSystemLoader('templates'))
  env.express(app)
  app.use express.errorHandler()



  app.use less
    src: path.join __dirname, 'public'
    once: true
    compress: true

  app.use express.favicon __dirname + '/public/images/favicon.ico'
  app.use express.static __dirname + '/public'

  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use (req, res)->
    res.status 404
    res.render '404.html'

app.get '/', (req, res)->
  res.render 'index.html'

app.use (err, req, res, next)->
  throw err
  res.status 500
  res.render '500.html'

http.createServer(app).listen process.env.PORT or 3000

console.log "Server running - on port " +(process.env.PORT or 3000)
