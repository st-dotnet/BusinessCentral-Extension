namespace Dynamic365.IServices
{
    public interface ISoapService
    {
        Task<string> GetTableFieldsAsync(string tableName);
    }
}
