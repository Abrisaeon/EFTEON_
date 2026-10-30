/**
 * This script handles fetching and displaying data in a table format from SAEON lognet sites with navigation and progress bars.
 * Author: Marc Pienaar
 * Email: m.pienaar@saeon.nrf.ac.za
 */
const navigationStack = [];
const lastClockedDates = {};
const storedLists = {};
let progressBarInterval = null;
let checkClockInterval = null;
let elapsedTimeInterval = null;
const elapsedTimes = {};
const startTimes = {};
const BASE_URL = "https://proxy.saeon.ac.za/lognet/?command=browsesymbols&uri=";
// Fetch and filter _std names



async function fetchStdNames() {
    const url = `${BASE_URL}Server:__statistics__&format=json&mode=most-recent&p1=1`;
    try {
        const response = await fetch(url);
        const data = await response.json();
        return data.symbols
            .filter(symbol => symbol.name.endsWith('_std'))
            .map(symbol => symbol.name);
    } catch (error) {
        console.error('Error fetching standard names:', error);
    }
}
// Fetch table data
async function fetchTableData(server) {
    const url = `${BASE_URL}${server}&format=json`;
    try {
        if (storedLists[server]) {
            return storedLists[server];
        }
        const response = await fetch(url);
        const json_data = await response.json();
        const names = json_data.symbols.map(item => item.name);
        const namesuri = json_data.symbols.map(item => item.uri);
        const canExpand = json_data.symbols.map(item => item.can_expand);
        storedLists[server] = {names, namesuri, canExpand};
        return storedLists[server];
    } catch (error) {
        console.error('Error fetching table data:', error);
    }
}
// Get tables and render the list
async function getTables(server) {
    document.getElementById('names-list').innerHTML = '';
    try {
        const {names, namesuri, canExpand} = await fetchTableData(server);
        if (server) {
            navigationStack.push(server);
        }
        renderList(names, namesuri, canExpand, server);
    } catch (error) {
        console.error('Error getting tables:', error);
    }
}
// Helper function to format elapsed time
function formatElapsedTime(milliseconds) {
    const totalSeconds = Math.round(milliseconds / 1000);
    const totalMinutes = Math.floor(totalSeconds / 60);
    const totalHours = Math.floor(totalMinutes / 60);
    if (totalHours > 0) {
        return `${totalHours}h ${totalMinutes % 60}m`;
    } else if (totalMinutes > 0) {
        return `${totalMinutes}m ${totalSeconds % 60}s`;
    } else {
        return `${totalSeconds}s`;
    }
}
function createPopupTable(jsonData) {
    const {head, data} = jsonData;
    const table = document.createElement("table");
    table.className = "styled-table"; // Add a class name to the table

    // Create table headers
    const nameHeaderRow = document.createElement("tr");
    const unitsHeaderRow = document.createElement("tr");
    const processHeaderRow = document.createElement("tr");
    // First column for 'time'
    const timeHeader = document.createElement("th");
    timeHeader.rowSpan = "3";
    timeHeader.textContent = "Time";
    nameHeaderRow.appendChild(timeHeader);
    // Fields
    head.fields.forEach(field => {
        const nameHeader = document.createElement("th");
        nameHeader.textContent = field.name;
        nameHeaderRow.appendChild(nameHeader);
        const unitsHeader = document.createElement("th");
        unitsHeader.textContent = field.units || '';
        unitsHeaderRow.appendChild(unitsHeader);
        const processHeader = document.createElement("th");
        processHeader.textContent = field.process || '';
        processHeaderRow.appendChild(processHeader);
    });
    table.appendChild(nameHeaderRow);
    table.appendChild(unitsHeaderRow);
    table.appendChild(processHeaderRow);
    // Create table body
    data.forEach(dataEntry => {
        const dataRow = document.createElement("tr");
        // Time column
        const timeCell = document.createElement("td");
        timeCell.textContent = dataEntry.time;
        dataRow.appendChild(timeCell);
        // Values columns
        dataEntry.vals.forEach(value => {
            const dataCell = document.createElement("td");
            dataCell.textContent = value;
            dataRow.appendChild(dataCell);
        });
        table.appendChild(dataRow);
    });
    // Create the Download button
    const downloadButton = document.createElement("button");

// Create an icon element using Font Awesome
    const downloadIcon = document.createElement("i");
    downloadIcon.classList.add("fas", "fa-file-download");

// Append icon and text to the button
    downloadButton.appendChild(downloadIcon);
    downloadButton.innerHTML += " Download Data";

// Add class to the button
    downloadButton.className = "download-data-btn";

// Append button to the document body
    document.body.appendChild(downloadButton);

    downloadButton.onclick = () => {
        // Convert table data to CSV format
        let csv = 'Time';
        head.fields.forEach(field => {
            csv += `, ${field.name} [${field.units || ''}] [${field.process || ''}]`;
        });
        csv += '\n';
        data.forEach(dataEntry => {
            csv += dataEntry.time;
            dataEntry.vals.forEach(value => {
                csv += `, ${value}`;
            });
            csv += '\n';
        });
        // Create a blob with the csv data
        const blob = new Blob([csv], {type: 'text/csv'});
        popupWindow.close();
        // Delay showing the prompt to allow the popup window to close
        setTimeout(() => {
            // Create a file name prompt
            const fileName = prompt('Enter file name:', 'data.csv');
            if (fileName) {
                // Create a link to download the CSV file
                const a = document.createElement('a');
                a.href = URL.createObjectURL(blob);
                a.download = fileName;
                // Trigger the download
                a.style.display = 'none';
                document.body.appendChild(a);
                a.click();
                document.body.removeChild(a);
            }
        }, 100);
    };
    const popupWidth = 800;
    const popupHeight = 600;
    const popupLeft = (window.innerWidth / 2) - (popupWidth / 2);
    const popupTop = (window.innerHeight / 2) - (popupHeight / 2);
    // Create a popup
    const popupWindow = window.open("", "Popup", `width=${popupWidth},height=${popupHeight},scrollbars=yes,resizable=yes,left=${popupLeft},top=${popupTop}`);

    const styles = `
.styled-table {
    width: 100%;
    margin: 25px 0;
    font-size: 0.9em;
    border-collapse: collapse;
    text-align: left;
}

.styled-table th, .styled-table td {
    padding: 12px 15px;
    border: 1px solid #dddddd;
}

.styled-table thead tr {
    background-color: #444; /* Updated color to dark gray */
    color: #ffffff;
    text-align: left;
}

.styled-table tbody tr:nth-of-type(even) {
    background-color: #f3f3f3;
}

.styled-table tbody tr:last-of-type {
    border-bottom: 2px solid #009879;
}

.download-data-btn {
    background-color: #4CAF50;
    border: none;
    color: white;
    padding: 8px 16px;
    text-align: center;
    text-decoration: none;
    display: inline-block;
    font-size: 14px;
    margin: 4px 2px;
    cursor: pointer;
    border-radius: 12px;
}
`;


    const styleSheet = document.createElement("style");
    styleSheet.type = "text/css";
    styleSheet.innerText = styles;
    popupWindow.document.head.appendChild(styleSheet);

// Append Font Awesome to the popup window
    const link = document.createElement("link");
    link.rel = "stylesheet";
    link.href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css";
    popupWindow.document.head.appendChild(link);

    popupWindow.document.body.appendChild(table);
    popupWindow.document.body.appendChild(downloadButton);
    popupWindow.document.body.appendChild(table);
}
function renderList(names, namesuri, canExpands, server) {
    const container = document.getElementById("names-list");
    container.innerHTML = '';

    const downloadButton = document.getElementById("download-button");
    downloadButton.onclick = () => {
        // Convert table data to CSV format
        let csv = 'Site, Clock Check, Elapsed Time\n';
        names.forEach((name, index) => {
            let elapsedTimeText = document.querySelectorAll('.elapsed-time')[index].textContent;
            let timestampText = document.querySelectorAll('.timestamp-text')[index].textContent;
            csv += `${name}, ${timestampText}, ${elapsedTimeText}\n`;
        });
        // Create a blob with the csv data
        const blob = new Blob([csv], {type: 'text/csv'});
        const fileName = prompt('Enter file name:', 'data.csv');
        if (fileName) {
            // Create a link to download the CSV file
            const a = document.createElement('a');
            a.href = URL.createObjectURL(blob);
            a.download = fileName;
            // Trigger the download
            a.style.display = 'none';
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
        }
        ;
    };
    // Append the download button to the container before the table
    // container.appendChild(downloadButton);
    if (navigationStack.length > 1) {
        const backButton = document.createElement("button");

// Create an icon element
        const backIcon = document.createElement("i");
        backIcon.classList.add("fas", "fa-arrow-left");

// Append icon and text to the button
        backButton.appendChild(backIcon);
        backButton.innerHTML += " Back";

// Add class to the button
        backButton.className = "back-btn";

// Append button to the document body
        document.body.appendChild(backButton);

        backButton.onclick = () => {
            navigationStack.pop();
            const previousServer = navigationStack.pop();
            getTables(previousServer);
        };
        container.appendChild(backButton); // Append back button to the container before the table
    }
    const table = document.createElement("table");
    container.appendChild(table);
    // Creating table header
    const thead = document.createElement("thead");
    table.appendChild(thead);
    const headerRow = document.createElement("tr");
    thead.appendChild(headerRow);
    const siteHeader = document.createElement("th");
    // Change the header text depending on whether it's the first table or not
    siteHeader.textContent = navigationStack.length > 1 ? "Tables" : "Site";
    headerRow.appendChild(siteHeader);
    const clockCheckHeader = document.createElement("th");
    clockCheckHeader.textContent = "Clock Check";
    headerRow.appendChild(clockCheckHeader);
    // Creating table rows
    const tbody = document.createElement("tbody");
    table.appendChild(tbody);
    // Add Elapsed Time column header
    const elapsedTimeHeader = document.createElement("th");
    elapsedTimeHeader.textContent = "Elapsed Time";
    headerRow.appendChild(elapsedTimeHeader);
    if (navigationStack.length === 1) {
        // First page, show Last Data Collection and Next Data Collection
        const lastDataCollectionHeader = document.createElement("th");
        lastDataCollectionHeader.textContent = "Last Data Collection";
        headerRow.appendChild(lastDataCollectionHeader);
        const nextDataCollectionHeader = document.createElement("th");
        nextDataCollectionHeader.textContent = "Next Data Collection";
        headerRow.appendChild(nextDataCollectionHeader);
    }
    // Record initialization time
    const initTime = Date.now();
    names.forEach((name, index) => {
        const row = document.createElement("tr");
        // Set the data-uri attribute for the row
        row.setAttribute("data-uri", namesuri[index]);
        tbody.appendChild(row);
        const nameCell = document.createElement("td");
        const link = document.createElement("a");
        link.textContent = name;
        link.href = "#";
        if (canExpands[index]) {
            link.onclick = (e) => {
                e.preventDefault();
                getTables(namesuri[index]);
            };
        } else {
            link.style.pointerEvents = 'none';
            link.style.color = 'grey';
        }
        nameCell.appendChild(link);
        // Add a space and a button next to the site name in subsequent tables
        if (navigationStack.length > 1) {
            const space = document.createTextNode(" "); // Create a space text node
            nameCell.appendChild(space); // Append the space
            const button = document.createElement("button");

// Create an icon element
            const icon = document.createElement("i");
            icon.classList.add("fas", "fa-download"); // using a download icon for "Get data"

// Append icon and text to the button
            button.appendChild(icon);
            button.innerHTML += " Get data";

// Add class to the button
            button.className = "get-data-btn";

// Append button to the document body
            document.body.appendChild(button);

            button.onclick = () => {
                // Log the specific URI when the button is clicked
                // console.log(`Button clicked for URI: ${namesuri[index]}`);
                const specificUri = namesuri[index];
                const queryUri = `https://proxy.saeon.ac.za/lognet/?command=dataquery&uri=${specificUri}&format=json&mode=since-time&p1=2010-01-01`;
                fetch(queryUri)
                    .then(response => response.json())
                    .then(data => createPopupTable(data))
                    .catch(error => console.error("Error fetching the data: ", error));
            };
            nameCell.appendChild(button); // Add the button next to the space
        }
        row.appendChild(nameCell);
        const statusCell = document.createElement("td");
        row.appendChild(statusCell);
        const progressWrapper = document.createElement("div");
        progressWrapper.className = 'progress-wrapper';
        statusCell.appendChild(progressWrapper);
        // Add progress bar
        const progressBar = document.createElement("progress");
        progressBar.setAttribute("value", "0");
        progressBar.setAttribute("max", "100");
        progressBar.className = 'progress-bar';
        progressWrapper.appendChild(progressBar);
        // Your timestampSpan element
        const timestampSpan = document.createElement("span");
        timestampSpan.className = 'timestamp-text';
        // Check if there is a last clocked date or NA value for this URI
        if (lastClockedDates[namesuri[index]]) {
            timestampSpan.textContent = lastClockedDates[namesuri[index]];
            timestampSpan.style.backgroundColor = 'orange'; // Or any color you want for previous values
        } else if (lastClockedDates[namesuri[index]] === " N/A") {
            timestampSpan.textContent = " N/A";
            timestampSpan.style.backgroundColor = 'red'; // Or any color you want for "NA" values
        } else {
            timestampSpan.textContent = "Waiting..."; // Default text
        }
        progressWrapper.appendChild(timestampSpan);
        // Start or continue the timer for this URI
        if (!elapsedTimes[namesuri[index]]) {
            elapsedTimes[namesuri[index]] = 0;
        }
        // // Create a new cell for elapsed time
        const elapsedTimeCell = document.createElement("td");
        elapsedTimeCell.className = 'elapsed-time';
        elapsedTimeCell.textContent = "0s";
        row.appendChild(elapsedTimeCell);
        if (navigationStack.length === 1) {
            const lastDataCollectionCell = document.createElement("td");
            lastDataCollectionCell.className = 'last-data-collection';
            row.appendChild(lastDataCollectionCell);
            const nextDataCollectionCell = document.createElement("td");
            nextDataCollectionCell.className = 'next-data-collection';
            row.appendChild(nextDataCollectionCell);
        }
    });
    const row = document.createElement("tr");
    tbody.appendChild(row);
    // Clear previously set intervals
    if (progressBarInterval) clearInterval(progressBarInterval);
    if (checkClockInterval) clearInterval(checkClockInterval);
    if (elapsedTimeInterval) clearInterval(elapsedTimeInterval);
    // Update progress bar every second
    progressBarInterval = setInterval(() => {
        const progressBars = document.querySelectorAll('.progress-bar');
        progressBars.forEach((progressBar) => {
            let currentValue = parseInt(progressBar.getAttribute("value"), 10);
            if (currentValue < 100) {
                progressBar.setAttribute("value", currentValue + 10);
            } else {
                progressBar.setAttribute("value", 0);
            }
        });
    }, 1000); // 1000 milliseconds or 1 second
    // Check clock status every 10 seconds
    checkClockInterval = setInterval(() => {
        namesuri.forEach((uri, index) => {
            const progressBar = document.querySelectorAll('.progress-bar')[index];
            progressBar.setAttribute("value", "0");
            const timestampSpan = document.querySelectorAll('.timestamp-text')[index];
            checkClock(uri, progressBar, timestampSpan);
        });
    }, 10000); // 10000 milliseconds or 10 seconds
    elapsedTimeInterval = setInterval(() => {
        const currentTime = Date.now();
        const elapsedTimeCells = document.querySelectorAll('.elapsed-time');
        elapsedTimeCells.forEach((elapsedTimeCell, index) => {
            const uri = namesuri[index];
            // Initialize start time for the site if not already initialized
            if (!startTimes[uri]) {
                startTimes[uri] = currentTime;
            }
            // Calculate the elapsed time based on the start time
            let elapsedTime = currentTime - startTimes[uri];
            // Update the elapsed time text content
            elapsedTimeCell.textContent = formatElapsedTime(elapsedTime);
        });
    }, 1000);
}
// Modify the checkClock function to also update the Last Data Collection and Next Data Collection
async function checkClock(uri, progressBar, timestampSpan) {
    // console.log(navigationStack.length);
    try {
        const url = `https://proxy.saeon.ac.za/lognet/?command=clockcheck&uri=${uri}&format=json`;
        const response = await fetch(url);
        const json_data = await response.json();
        if (json_data.outcome === 1) {
            timestampSpan.style.backgroundColor = 'green'; // Ensure background color is set to green
            timestampSpan.textContent = ' ' + json_data.time;
            lastClockedDates[uri] = json_data.time;
            // Reset the start time for this site as status is green
            startTimes[uri] = Date.now();
        } else {
            if (lastClockedDates[uri]) {
                timestampSpan.style.backgroundColor = 'orange';
                timestampSpan.textContent = ' ' + lastClockedDates[uri];
            } else {
                timestampSpan.style.backgroundColor = 'red';
                timestampSpan.textContent = " N/A";
            }
        }
        if (navigationStack.length === 1) {
            const siteUri = uri;
            fetchStdNames().then(stdNames => {
                const siteNameParts = siteUri.split(':');
                const partToMatch = siteNameParts[1];
                const bestMatch = stdNames.find(stdName => stdName.startsWith(partToMatch) && stdName.endsWith('_std'));
                if (bestMatch) {
                    const url = `https://proxy.saeon.ac.za/lognet/?command=dataquery&uri=Server:__Statistics__.${bestMatch}&format=json&mode=most-recent&p1=1`;
                    fetch(url)
                        .then(response => response.json())
                        .then(data => {
                            const fields = data.head.fields;
                            let lastIndex = -1,
                                nextIndex = -1;
                            for (let i = 0; i < fields.length; i++) {
                                if (fields[i].name === "Last Data Collection") {
                                    lastIndex = i;
                                } else if (fields[i].name === "Next Data Collection") {
                                    nextIndex = i;
                                }
                            }
                            let lastDataCollectionValue = 'N/A',
                                nextDataCollectionValue = 'N/A';
                            if (data.data.length > 0) {
                                if (lastIndex !== -1 && data.data[0].vals.length > lastIndex) {
                                    lastDataCollectionValue = data.data[0].vals[lastIndex];
                                }
                                if (nextIndex !== -1 && data.data[0].vals.length > nextIndex) {
                                    nextDataCollectionValue = data.data[0].vals[nextIndex];
                                }
                            }
                            const row = document.querySelector(`tr[data-uri="${siteUri}"]`);
                            const lastDataCollectionCell = row ? row.querySelector(".last-data-collection") : null;
                            const nextDataCollectionCell = row ? row.querySelector(".next-data-collection") : null;
                            if (lastDataCollectionCell && nextDataCollectionCell) {
                                lastDataCollectionCell.textContent = lastDataCollectionValue;
                                nextDataCollectionCell.textContent = nextDataCollectionValue;
                            }
                        })
                        .catch(error => console.error(`Error fetching data for ${bestMatch}:`, error));
                }
            });
        }
    } catch (error) {
        // If there is an error, display the last known value or N/A
        if (lastClockedDates[uri]) {
            timestampSpan.style.backgroundColor = 'orange';
            timestampSpan.textContent = ' ' + lastClockedDates[uri];
        } else {
            timestampSpan.style.backgroundColor = 'red';
            timestampSpan.textContent = " N/A";
        }
    }
}
window.onload = async function () {
    await getTables("Server");
}
