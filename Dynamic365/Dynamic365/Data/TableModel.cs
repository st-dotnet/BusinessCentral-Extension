using Newtonsoft.Json;

namespace Dynamic365.Data
{
    public class TableModel
    {
        [JsonProperty("TableID")]  // Ensure correct mapping
        public int TableID { get; set; }

        [JsonProperty("TableName")]
        public string TableName { get; set; }
    }
}
