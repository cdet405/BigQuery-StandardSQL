// Triggered Every Morning 2am to fetch CAD>USD rate and write to table
function runQuery() {
  
  var key = 'REDACTED-API-KEY';  
  var url = "https://v6.exchangerate-api.com/v6/"+key+"/pair/CAD/USD";
  // Fetch CAD to USD Conversion Rate
  var response = UrlFetchApp.fetch(url);
  var data = JSON.parse(response.getContentText());
  let ts = data.time_last_update_unix;
  let rate = data.conversion_rate;
  
   // Insert ProjectID
  const projectId = 'REDACTED_PROJECT_ID';

  const request = {
    // Query for insert
    query: 'INSERT INTO `PROJECT_ID.DATASET.rate` (ts, rate) VALUES ('+ts+','+rate+');',
    useLegacySql: false
  };
  let queryResults = BigQuery.Jobs.query(request, projectId);
  const jobId = queryResults.jobReference.jobId;

  // Check on status of the Query Job.
  let sleepTimeMs = 500;
  while (!queryResults.jobComplete) {
    Utilities.sleep(sleepTimeMs);
    sleepTimeMs *= 2;
    queryResults = BigQuery.Jobs.getQueryResults(projectId, jobId);
  }
}
