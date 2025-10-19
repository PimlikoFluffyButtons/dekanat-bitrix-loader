using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.IO;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.AspNetCore.Hosting;

namespace TeachersApi21.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class TeachersController : ControllerBase
    {
        private readonly IConfiguration _cfg;
        private readonly IHostingEnvironment _env;

        public TeachersController(IConfiguration cfg, IHostingEnvironment env)
        {
            _cfg = cfg;
            _env = env;
        }

        [HttpGet("/health")]
        public IActionResult Health() =>
            Ok(new { status = "ok", time = DateTime.UtcNow });

        [HttpGet]
        public IActionResult Get()
        {
            // --- API key ---
            var expectedKey = _cfg["ApiKey"] ?? Environment.GetEnvironmentVariable("API_KEY");
            var key = Request.Headers["X-Api-Key"].ToString();
            if (string.IsNullOrEmpty(key))
                key = Request.Query["key"].ToString();

            if (!string.Equals(key, expectedKey, StringComparison.Ordinal))
                return StatusCode(401, new { error = "unauthorized" });

            // --- Connection string ---
            var connStr = _cfg.GetConnectionString("Dekanat")
                          ?? Environment.GetEnvironmentVariable("DEKANAT_CONNSTR");
            if (string.IsNullOrWhiteSpace(connStr))
                return StatusCode(500, new { error = "missing_connection_string" });

            // --- Read SQL from file ---
            var sqlPath = Path.Combine(_env.ContentRootPath, "main_query.sql");
            if (!System.IO.File.Exists(sqlPath))
                return StatusCode(500, new { error = "sql_file_not_found", path = sqlPath });

            var sql = System.IO.File.ReadAllText(sqlPath);

            var rows = new List<Dictionary<string, object>>();

            try
            {
                using (var conn = new SqlConnection(connStr))
                using (var cmd = new SqlCommand(sql, conn))
                {
                    conn.Open();
                    using (var r = cmd.ExecuteReader())
                    {
                        while (r.Read())
                        {
                            var obj = new Dictionary<string, object>(StringComparer.OrdinalIgnoreCase);
                            for (int i = 0; i < r.FieldCount; i++)
                            {
                                object val = r.IsDBNull(i) ? null : r.GetValue(i);
                                if (val is DateTime dt) val = dt.ToUniversalTime().ToString("o");
                                obj[r.GetName(i)] = val;
                            }
                            rows.Add(obj);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = "sql_error", message = ex.Message });
            }

            return new JsonResult(rows);
        }
    }
}
