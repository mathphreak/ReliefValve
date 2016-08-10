const fs = require('fs');
const shell = require('shelljs');
const archiver = require('archiver');

const version = require('./package.json').version;

shell.cd('dist/');

const systems = [];

shell.ls().forEach(folder => {
  if (folder.startsWith('relief-valve')) {
    const [, , platform, arch] = folder.split('-');
    const id = `${platform}-${arch}`;
    systems.push(id);
    shell.mkdir(id);
    shell.mv(folder, `${id}/Relief Valve v${version}`);
  }
});

shell.cd('..');

shell.mkdir('build');

systems.forEach(id => {
  if (id === 'darwin-x64') {
    shell.pushd('dist/darwin-x64');
    shell.exec(`tar czf ../../build/Relief-Valve-v${version}-${id}.tar.gz *`);
    console.log(`Built for ${id}`);
    shell.popd();
  } else {
    const archive = archiver.create('zip');
    const out = fs.createWriteStream(`build/Relief-Valve-v${version}-${id}.zip`);
    archive.on('end', () => console.log(`Built for ${id}`));
    archive.directory(`dist/${id}/`, '/');
    archive.finalize();
    archive.pipe(out);
  }
});
