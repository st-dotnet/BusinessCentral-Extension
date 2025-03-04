using Dynamic365.Data;
using Dynamic365.IServices;
using Dynamic365.Services;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(connectionString));
builder.Services.AddDatabaseDeveloperPageExceptionFilter();

builder.Services.AddDefaultIdentity<IdentityUser>(options => options.SignIn.RequireConfirmedAccount = true)
    .AddEntityFrameworkStores<ApplicationDbContext>();
builder.Services.AddControllersWithViews();

// Register HttpClient for dependency injection
builder.Services.AddHttpClient();

// Register AuthenticationService and Dynamics365Service
builder.Services.AddSingleton<AuthenticationService>();
builder.Services.AddScoped<ISoapService, SOAPServiceCall>();
builder.Services.AddScoped<IGetAllTablesServices, GetAllTables>();

builder.Services.AddHttpClient<GetAllTables>(client =>
{
    client.Timeout = TimeSpan.FromSeconds(30);
});



builder.Services.AddControllersWithViews();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseMigrationsEndPoint();
}
else
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Customer}/{action=Index}/{id?}");

app.MapRazorPages(); 
app.Run();
