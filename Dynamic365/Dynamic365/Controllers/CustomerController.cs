using Dynamic365.Data;
using Dynamic365.IServices;
using Dynamic365.Services;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;
using System.Xml.Linq;

namespace Dynamic365.Controllers
{
    public class CustomerController : Controller
	{
        private readonly ISoapService _soapService;
        private readonly IGetAllTablesServices _getAllTablesServices;

        public CustomerController( ISoapService soapService, IGetAllTablesServices getAllTables)
		{
            _soapService = soapService;
            _getAllTablesServices = getAllTables;
        }

        public async Task<IActionResult> Index()
        {
            // Call the SOAP service
            var soapResponse = _getAllTablesServices.GetTables();

            // Extract the JSON content between <return_value></return_value>
            string jsonData = ExtractJsonFromSoap(await soapResponse);

            // Convert the JSON string into a C# object (List)
            var tablesList = JsonConvert.DeserializeObject<List<TableModel>>(jsonData);

            // Pass the extracted data to the View using ViewBag
            ViewBag.Tables = tablesList;

            return View();
        }

        [HttpGet] 
        public async Task<IActionResult> GetTableFields([FromQuery] string tableName)
        {
            if (string.IsNullOrEmpty(tableName))
            {
                return Json(new { error = "Table name is required" });
            }

            var tableFields = await _soapService.GetTableFieldsAsync(tableName);
            return Json(tableFields);
        }

        #region Private Methods
        private string ExtractJsonFromSoap(string soapResponse)
        {
            try
            {
                XDocument doc = XDocument.Parse(soapResponse);

                // Locate the <return_value> node
                var returnValueNode = doc.Descendants()
                                         .FirstOrDefault(x => x.Name.LocalName == "return_value");

                if (returnValueNode == null)
                    return "[]"; // Return empty JSON if not found

                string extractedJson = returnValueNode.Value.Trim();

                // Ensure JSON is correctly formatted
                if (!extractedJson.StartsWith("[") || !extractedJson.EndsWith("]"))
                {
                    return "[]"; // Return empty JSON if format is incorrect
                }

                return extractedJson;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error parsing SOAP response: {ex.Message}");
                return "[]";
            }
        }
        #endregion
    }
}
