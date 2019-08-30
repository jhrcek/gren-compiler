#!/usr/bin/env node

var child_process = require('child_process');
var download = require('../download.js');
var fs = require('fs');


// Some npm users enable --ignore-scripts (a good security measure)
//
// They do not run the post-install hook, so install.js does not run.
//
// This file pretends to be the downloaded binary. It then downloads
// the real binary over itself. So in that case, the first run would
// also make an HTTPS request to fetch the real binary. From there,
// it calls the binary it downloaded on each run.



// Make sure we get the right path even if we're executing from the symlinked
// node_modules/.bin/ executable
var targetPath = fs.realpathSync(process.argv[1]);

download(targetPath, runOriginalCommandWithDownloadedBinary);


// If the binary downloads successfully, try to run the original command.
function runOriginalCommandWithDownloadedBinary()
{
	// Need double quotes and { shell: true } when there are spaces in the path on windows:
	// https://github.com/nodejs/node/issues/7367#issuecomment-229721296
	//
	child_process
		.spawn('"' + targetPath + '"', process.argv.slice(2), { stdio: 'inherit', shell: true })
		.on('exit', process.exit);
}
