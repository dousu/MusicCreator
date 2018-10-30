const glob = require('glob');
const fs = require('fs');
glob('./static/abc/*.abc', (_, files) => {
    fs.writeFileSync(__dirname + '/static/index.json', JSON.stringify(files.map((file) => fs.readFileSync(file, 'utf-8'))))
});