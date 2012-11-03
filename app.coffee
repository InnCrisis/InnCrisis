express = require 'express'
http = require 'http'
path = require 'path'
less = require 'less-middleware'
nunjucks = require 'nunjucks'
request = require 'request'
Kinvey = require 'kinvey'

Kinvey.init
  appKey: 'kid_eeg1EyERV5'
  masterSecret: '0385617783be46ffa9ba48cc9482bdec'

donations = new Kinvey.Collection('donations')

wepaySettings =
  clientId     : '189346'
  clientSecret : '95e1702291'
  accessToken  : '654d1dee01cd77a3aec989b216997396ff937c5c501e18f45a2af82ec36b7fcd'
  accountId    : '180153296'
  baseUri: 'https://stage.wepayapi.com/v2/'


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
  res.render 'index.html',

app.get '/getaroom', (req, res)->
  res.render 'getaroom.html'

app.get '/donate', (req, res)->
  if !req.query.amount?.length
    res.render 'donate.html'
  else
    request.get
      uri: wepaySettings.baseUri+'checkout/create'
      headers:
        "User-Agent":"Nodejs"
        Authorization: 'Bearer '+wepaySettings.accessToken
      form:
        account_id:wepaySettings.accountId
        amount: req.query.amount
        short_description: 'Short description!'
        type: 'DONATION'
        mode: 'regular'
        redirect_uri: 'http://localhost:3000/thankyou'
      (err, response, body)->
        res.redirect JSON.parse(body).checkout_uri

app.get '/thankyou', (req, res)->
  request.get
    uri: wepaySettings.baseUri+'checkout'
    headers:
      "User-Agent":"Nodejs"
      Authorization: 'Bearer '+wepaySettings.accessToken
    form:
      checkout_id:req.query.checkout_id
    (err, response, body)->
      donation = JSON.parse(body)
      donationId = donation.checkout_id
      delete donation.checkout_id

      kDonation = new Kinvey.Entity(donation,'donations')
      kDonation.setId(donationId)
      kDonation.save()
      res.render 'thankyou.html',
        checkout_id: donationId


app.get '/track', (req, res)->
  donation = new Kinvey.Entity({}, 'donations');
  donation.load req.query.checkout_id,
    success: (response)->
      res.render 'track.html',
        donation: JSON.stringify(response,0,2)
    error: ()->
      res.render '500.html'


app.use (err, req, res, next)->
  throw err
  res.status 500
  res.render '500.html'

http.createServer(app).listen process.env.PORT or 3000

console.log "Server running - on port " +(process.env.PORT or 3000)
