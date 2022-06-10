const fs = require("fs");
// var moment = require("moment"); // require
const data = require("./json/_metadata.json");

let metaData = data;
let metaData1 = [
    {
        "name": "Crypto Outlaws #5648",
        "description": "7,777 Outlaws conquering the wild west of crypto and bringing decentralized hold em to the blockchain",
        "image": "ipfs://NewUriToReplace/5648.png",
        "dna": "d41634f06824bf0bb2373d5c909670d7d80ed530",
        "edition": 5648,
        "date": 1648980227918,
        "attributes": [
            {
                "trait_type": "Background",
                "value": "5"
            },
            {
                "trait_type": "Couch",
                "value": "5"
            },
            {
                "trait_type": "Leopards",
                "value": "3"
            },
            {
                "trait_type": "Clothes",
                "value": "6"
            },
            {
                "trait_type": "Necklace",
                "value": "Non"
            },
            {
                "trait_type": "Watches",
                "value": "2"
            },
            {
                "trait_type": "Eyes",
                "value": "13"
            },
            {
                "trait_type": "Eyewear",
                "value": "Non"
            },
            {
                "trait_type": "Hatwear",
                "value": "2"
            },
            {
                "trait_type": "Mouth",
                "value": "3"
            },
            {
                "trait_type": "Earring",
                "value": "6"
            },
            {
                "trait_type": "Table",
                "value": "7"
            },
            {
                "trait_type": "On the table",
                "value": "6"
            },
            {
                "trait_type": "Stuff",
                "value": "7"
            },
            {
                "trait_type": "Left Hand",
                "value": "3"
            },
            {
                "trait_type": "Right Hand",
                "value": "4"
            },
            {
                "trait_type": "Rings",
                "value": "7"
            }
        ],
        "compiler": "HashLips Art Engine"
    }
];

let updatedMetaa = [];

async function updateMetaData() {
    for (let index = 0; index < 2; index++) {
        // const element = array[i];


        // let obj = {};
        // let attributes = [];
        // obj.name =
        //     metaData[index].IcecatID +
        //     " " +
        //     metaData[index].Brand +
        //     " " +
        //     metaData[index].Category;
        // obj.external_url = metaData[index].Permalink;
        // obj.description = "";
        // obj.image = `ipfs://QmWrDA9ejhKrHzUdhSVRBrUAdJDcdXZcpZitWeZHr53iYH/${index}.png`;

        let metaDataObj = metaData[index];

        // for (let key in metaDataObj) {
        //     key !== "Permalink" &&
        //         attributes.push(
        //             key !== "TimeStamp"
        //                 ? {
        //                     trait_type: key,
        //                     value: metaDataObj[key],
        //                 }
        //                 : {
        //                     display_type: "date",
        //                     trait_type: key,
        //                     // value:
        //                     //   new Date(
        //                     //     moment(metaDataObj[key], "DD-MM-YYYY").format(
        //                     //       "YYYY-MM-DD"
        //                     //     )
        //                     //   ).getTime() / 1000,
        //                 }
        //         );
        // }

        // obj.attributes = attributes;

        updatedMetaa.push(metaDataObj);
    }
}

updateMetaData().then(() => {
    updatedMetaa.map((item, index) => {
        fs.writeFileSync(
            `./pinataJson/${index}.json`,
            JSON.stringify(item, null, 4)
        );
    });
});
