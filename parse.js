const parser = require('./emoji.js');
const escodegen = require('escodegen');
const fs = require('fs');

const input = fs.readFileSync(process.argv[2], 'utf8');

const ast = parser.parse(input);
const code = escodegen.generate(ast);
console.log(`
コード生成結果:
${code}
-----------------
実行結果:`);
eval(code);