const fs = require('fs');

function loadJsonFile(filePath) {
    try {
        const fileContent = fs.readFileSync(filePath, 'utf8');
        return JSON.parse(fileContent);
    } 
    catch (error) {
        console.error(`Error reading file from disk: ${error}`);
        return null;
    }
}

const myData = loadJsonFile('scripts/params.json');

if (myData) {
    console.log(myData['Uniswap']);
}

