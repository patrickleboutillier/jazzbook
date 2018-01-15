#!/usr/bin/node 

const Datastore = require('@google-cloud/datastore') ;
const express = require('express') ;

const datastore = new Datastore({ projectId: process.env.GOOGLE_CLOUD_PROJECT }) ;
const app = express() ;

app.set('view engine', 'pug')
app.use(express.static('public')) ;

// List books using 'index' template
app.get('/', function(req, res){
	const query = datastore.createQuery('book')
 		.order('title') ;
	datastore.runQuery(query)
		.then((results) => {
			var books = results[0] ;
			books.forEach(book => { book.key = book[Datastore.KEY].name }) ;
			console.log(books) ;
			res.render('index', { books: books }) ;
		})
		.catch((err) => {
			console.error('ERROR:', err) ;
			res.sendStatus(500) ;
		}) ;
}) ;

// List tunes in book using 'book' template
app.get('/book/:title', function(req, res){
	var key = datastore.key(['book', req.params.title]) ;
	datastore.get(key)
		.then((results) => {
			if (results[0] != null){
				const book = results[0] ;
				if (book.tunes != null){
					book.tunes.sort() ;
				}
				console.log(`Book ${book.title} loaded from Datastore.`) ;
				res.render('book', book) ;
			}
			else {
				res.sendStatus(404) ;
			}
		})
		.catch((err) => {
			console.error('ERROR:', err) ;
			res.sendStatus(500) ;
		}) ;
}) ;

app.get('/tune/:title', function(req, res){
	var key = datastore.key(['tune', req.params.title]) ;
	datastore.get(key)
		.then((results) => {
			if (results[0] != null){
				const tune = results[0] ;
				console.log(`Tune ${tune.title} loaded from Datastore.`) ;
				res.json(tune) ;
			}
			else {
				res.sendStatus(404) ;
			}
		})
		.catch((err) => {
			console.error('ERROR:', err) ;
			res.sendStatus(500) ;
		}) ;
}) ;

const PORT = process.env.PORT || 8080 ;
app.listen(PORT, () => console.log('Server listening on port ' + PORT)) ;

