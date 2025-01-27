const fs = require('fs');
const willhaben = require('willhaben');
const notifyChanges = require('./notifier'); // Import the function

//https://github.com/CP02A/willhaben

process.chdir(__dirname);
console.log(process.cwd());  // prints the current working directory
//console.log(__dirname);      // prints the directory where the script is located

var datetime_now = new Date();
//datetime_now.setDate(datetime_now.getDate() - 1);

const options = {
    spaces: 4,
    EOL: '\n',
};

const searchqueries = [
    //"https://www.willhaben.at/iad/kaufen-und-verkaufen/marktplatz?sort=1&rows=20000&isNavigation=true&keyword=\"Iphone+13+pro+max\"&PRICE_FROM=200&PRICE_TO=450&count=10000&page="
    "https://www.willhaben.at/iad/kaufen-und-verkaufen/marktplatz?sort=1&rows=20000&isNavigation=true&keyword=\"Iphone+15+pro+max\"&PRICE_FROM=250&PRICE_TO=550&count=10000&page=",
    "https://www.willhaben.at/iad/kaufen-und-verkaufen/marktplatz?sort=1&rows=20000&isNavigation=true&keyword=\"Prusa mk4\"&PRICE_FROM=100&PRICE_TO=950&count=10000&page=",
    "https://www.willhaben.at/iad/kaufen-und-verkaufen/marktplatz?sort=1&rows=20000&isNavigation=true&keyword=Ubiquiti&PRICE_FROM=20&PRICE_TO=550&count=10000&page="
];
//let i = 0;

const changesFile = "0_price_changes.json";
const csvFile = "0_price_changes.csv";
// Initialize CSV header
let csvData = "My-OldPrice;Sys-OldPrice;NewPrice;My-Delta;Sys-Delta;ReductionDate;PublishDate;EndDate;Description;URL";
if (fs.existsSync(csvFile)) {
    csvData = fs.readFileSync(csvFile, 'utf8');
}

let changes = [];
if (fs.existsSync(changesFile)) {
    changes = JSON.parse(fs.readFileSync(changesFile, 'utf8'));
}



searchqueries.forEach((value, index) => {
    //const searchquery = "https://www.willhaben.at/iad/kaufen-und-verkaufen/marktplatz?sort=1&rows=20000&isNavigation=true&keyword=\"Iphone+13+pro+max\"&PRICE_FROM=200&PRICE_TO=450&count=10000&page=";
    const searchquery = value;

    console.log(searchquery);

    let changes_run = [];
    let page = 1;
    let masterjson = [];
    const previousFile = "0_previous_run_" + index + ".json";

    // Load previous run data
    let previousData = [];
    if (fs.existsSync(previousFile)) {
        previousData = JSON.parse(fs.readFileSync(previousFile, 'utf8'));
    }

    // Start fetching data
    getData();

    function getData() {
        const site = searchquery + page;
        console.log("Page " + page);

        willhaben.getListings(site).then(json => {
            masterjson.push(...json);

            // If there are more pages, continue
            console.log("Length " + json.length);
            if (json.length === 200) {
                page += 1;
                getData();
            } else {
                processResults();
            }
        }).catch(err => {
            console.error("Error fetching data:", err);
        });
    }

    function processResults() {
        console.log("Processing results...");

        // Identify changes
        const currentData = masterjson.reduce((acc, item) => {
            acc[item.id] = item;
            return acc;
        }, {});
        //console.log(currentData);
        for (const oldItem of previousData) {
            const currentItem = currentData[oldItem.id];
            if (currentItem) {
                // Check for price changes
                if (currentItem.price !== oldItem.price) {
                    const reductionDate = currentItem.price_reduction_set_date_string ?? "unknown";
                    const changeEntry = {
                        id: currentItem.id,
                        my_old_price: oldItem.price,
                        sys_old_price: currentItem.old_price,
                        new_price: currentItem.price,
                        my_delta_price: currentItem.price-oldItem.price,
                        sys_delta_price: currentItem.price-currentItem.old_price,
                        //reduction_date: reductionDate.slice(0, 10),
                        reduction_date: reductionDate,
                        publish_date: currentItem.published_string.slice(0, 10),
                        end_date: currentItem.enddate_string.slice(0, 10),
                        description: currentItem.description,
                        url: "https://www.willhaben.at/iad/" + currentItem.seo_url,
                    };
                    changes.push(changeEntry);
                    changes_run.push(changeEntry);

                    // Add to CSV
                    csvData += `\n${changeEntry.my_old_price};${changeEntry.sys_old_price};${changeEntry.new_price};${changeEntry.new_price-changeEntry.my_old_price};${changeEntry.new_price-changeEntry.sys_old_price};${changeEntry.reduction_date};${changeEntry.publish_date};${changeEntry.end_date};${changeEntry.description};${changeEntry.url}`;
                }
            }
        }
        const changesData = changes.reduce((acc, item) => {
            acc[item.id] = item;
            return acc;
        }, {});
        for (const currentItem of masterjson) {
            if ("price_reduction_set_date_string" in currentItem) {
                //console.log(currentItem);
                //console.log(currentItem.price_reduction_set_date_string.slice(0, 10) + " jetzt " + datetime_now.toISOString().slice(0,10))
                if (currentItem.price_reduction_set_date_string.slice(0, 10) === datetime_now.toISOString().slice(0,10)) {
                    const changesItem = changesData[currentItem.id];
                    if ((currentItem?.price_reduction_set_date_string ?? null) !== (changesItem?.reduction_date ?? null)) {
                        console.log(currentItem.id + " Change in date");
                        const changeEntry = {
                            id: currentItem.id,
                            sys_old_price: currentItem.old_price,
                            new_price: currentItem.price,
                            sys_delta_price: currentItem.price-currentItem.old_price,
                            //reduction_date: reductionDate.slice(0, 10),
                            reduction_date: currentItem.price_reduction_set_date_string,
                            publish_date: currentItem.published_string.slice(0, 10),
                            end_date: currentItem.enddate_string.slice(0, 10),
                            description: currentItem.description,
                            url: "https://www.willhaben.at/iad/" + currentItem.seo_url,
                        };
                        changes.push(changeEntry);
                        changes_run.push(changeEntry);

                        // Add to CSV
                        csvData += `\n${changeEntry.my_old_price};${changeEntry.sys_old_price};${changeEntry.new_price};${changeEntry.new_price-changeEntry.my_old_price};${changeEntry.new_price-changeEntry.sys_old_price};${changeEntry.reduction_date};${changeEntry.publish_date};${changeEntry.end_date};${changeEntry.description};${changeEntry.url}`;
                    }
                    else {
                        console.log(currentItem.id + " Change already monitored");
                    }
                }
            }
            
        }


        // Save changes to file
        fs.writeFileSync(changesFile, JSON.stringify(changes, null, options.spaces), "utf8");
        console.log(`Changes saved to ${changesFile}.`);
        notifyChanges(changes_run);
        
        // Save CSV file
        fs.writeFileSync(csvFile, csvData, "utf8");
        console.log(`Price changes saved to ${csvFile}.`);

        // Save current data for next run
        fs.writeFileSync(previousFile, JSON.stringify(masterjson, null, options.spaces), "utf8");
        console.log(`Current data saved to ${previousFile}.`);
    }
    //i=i+1;
});
