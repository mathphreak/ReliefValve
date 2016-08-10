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
  const format = id === 'darwin-x64' ? 'tar' : 'zip';
  const extension = id === 'darwin-x64' ? 'tar.gz' : 'zip';
  const archive = archiver.create(format);
  const out = fs.createWriteStream(`build/Relief-Valve-v${version}-${id}.${extension}`);
  archive.on('end', () => console.log(`Built for ${id}`));
  archive.directory(`dist/${id}/`, '/');
  archive.finalize();
  archive.pipe(out);
});
