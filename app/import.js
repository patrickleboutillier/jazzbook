#!/usr/bin/node 

var files = process.argv.slice(2) ;
var fs = require('fs') ;
var sync = require('sync') ;

// Imports the Google Cloud client library
const Datastore = require('@google-cloud/datastore');

// Your Google Cloud Platform project ID
const projectId = process.env.GOOGLE_CLOUD_PROJECT ;

// Creates a client
const datastore = new Datastore({
  projectId: projectId,
});


sync(files.forEach(update_tune)) ;


function update_tune(filename){
	var tune = JSON.parse(fs.readFileSync(filename).toString()) ;

	// The Cloud Datastore key for the new entity
	const taskKey = datastore.key(['tune', tune.title]) ;

	// Prepares the new entity
	const task = {
	  key: taskKey,
	  data: tune
	};

	// Saves the entity
	datastore
	  .save(task)
	  .then(() => {
	    // console.log(`Saved ${task.key.name}: ${task.data.title}`) ;
	  })
	  .catch(err => {
	    console.error('ERROR:', err, filename);
	  });
}
