# QSLoopAndReduce

## What is Loop and Reduce:
- Workflow that dynamically splits each user/group’s data into their own distinct app loaded with their own data, built off of a template app.

## When should I use Loop and Reduce:
- If the total separation of each groups’ data is the top priority due to InfoSec requirements.
- If an ODAG summary page is not required as part of the use case’s workflow.
- If data reduction over multiple dimensions is not required for the use case, one dimension is enough.
- Can be used to split QVDs for use with session apps.

## Loop and Reduce considerations:
- Requires QRS calls (e.g. using Qlik-Cli)
- Extra load on data source when compared to ODAG, since we’re reloading data for each user.
- Storage considerations for both QVD’s and apps.

![Architecture](https://github.com/fadyheiba/QSLoopAndReduce/blob/master/Documentation/Architecture.png?raw=true)

## QVD Splitter Structure
- Create list of groups, save as CSV to disk. 
- Loop over each group, loading only the group’s data from the source
- Create new folder for each group and save their data into QVD’s 

## Template App Structure
- Loads QVDs from the folder the QVD Splitter created. 
- Uses DocumentTitle() to determine the group’s folder name.

## Powershell Script Structure (using Qlik-Cli)
- If custom property/stream are not created, create custom property/stream.
- For each value in the CSV list:
  - If app for this value doesn’t exist:
    - Create app with correct name/owner/custom property.
    - Publish it to stream.
    - Create task, and run it.
- If app for this value does exist:
  - Find the app’s task and run it.

