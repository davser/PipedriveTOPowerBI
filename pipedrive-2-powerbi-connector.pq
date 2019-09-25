//A basic direct connector to pipedrive api

//The [Query] syntax is used because PowerBI doesn't work well with api tokens by QueryString

//This first part will get all the total deal records

let 
Source = Json.Document(Web.Contents("https://mypipedrive.pipedrive.com/v1/deals:(id)?api_token=12345",[Query=[api_token="12345", limit="1", start="0", get_summary="1"]])), 
#"Converted to Table Record" = Record.ToTable(Source),
Value = #"Converted to Table Record"{2}[Value],
summary = Value[summary],
total_records = summary[total_count],

//This second part, tries to resolve the maximum limit value of 500 that pipedrive have
//Starts 0, 500, 1000, 1500 until the total records

Starts = List.Generate(()=>0, each _ < total_records, each _ + 500), 
#"Converted to Table" = Table.FromList(Starts, Splitter.SplitByNothing(), null, null, ExtraValues.Error), 
#"Changed Type" = Table.TransformColumnTypes(#"Converted to Table",{{"Column1", type text}}), 
#"Added Custom" = Table.AddColumn(#"Changed Type", "Custom", each Json.Document(Web.Contents("https://mypipedrive.pipedrive.com/v1/deals:(user_id,org_id)?api_token=12345",[Query=[api_token="12345", limit="500", start=[Column1]]]))),

//then is just branding and expanding
#"Expanded Custom" = Table.ExpandRecordColumn(#"Added Custom", "Custom", {"data"}, {"Custom.data"}),
#"Expanded Custom.data" = Table.ExpandListColumn(#"Expanded Custom", "Custom.data"),
#"Expanded Custom.data1" = Table.ExpandRecordColumn(#"Expanded Custom.data", "Custom.data", {"user_id", "org_id"}),
#"Expanded user_id" = Table.ExpandRecordColumn(#"Expanded Custom.data1", "user_id", {"name"}, {"name"}),
#"Expanded org_id" = Table.ExpandRecordColumn(#"Expanded user_id", "org_id", {"name"}, {"name.1"}),
in
#"Expanded org_id"
