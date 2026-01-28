using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using PikApi.Data;
using PikApi.DTOs;
using PikApi.Entities;
using PikApi.Entities.Enums;

namespace PikApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly UserManager<IdentityUser> _userManager;
        private readonly SignInManager<IdentityUser> _signInManager;
        private readonly RoleManager<IdentityRole> _roleManager;
        private readonly ApplicationDbContext _context;
        private readonly IConfiguration _configuration;

        public AuthController(
            UserManager<IdentityUser> userManager,
            SignInManager<IdentityUser> signInManager,
            RoleManager<IdentityRole> roleManager,
            ApplicationDbContext context,
            IConfiguration configuration)
        {
            _userManager = userManager;
            _signInManager = signInManager;
            _roleManager = roleManager;
            _context = context;
            _configuration = configuration;
        }

        /// <summary>
        /// POST /api/auth/login
        /// Đăng nhập và trả về JWT Token
        /// </summary>
        [HttpPost("login")]
        public async Task<ActionResult<AuthResponse>> Login([FromBody] LoginRequest request)
        {
            var user = await _userManager.FindByEmailAsync(request.Email);
            if (user == null)
            {
                return Unauthorized(new AuthResponse
                {
                    Success = false,
                    Message = "Email hoặc mật khẩu không đúng"
                });
            }

            var result = await _signInManager.CheckPasswordSignInAsync(user, request.Password, false);
            if (!result.Succeeded)
            {
                return Unauthorized(new AuthResponse
                {
                    Success = false,
                    Message = "Email hoặc mật khẩu không đúng"
                });
            }

            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == user.Id);
            var roles = await _userManager.GetRolesAsync(user);
            var token = GenerateJwtToken(user, roles, member);

            return Ok(new AuthResponse
            {
                Success = true,
                Token = token,
                ExpiresAt = DateTime.UtcNow.AddMinutes(int.Parse(_configuration["Jwt:ExpireMinutes"] ?? "1440")),
                User = new UserInfo
                {
                    UserId = user.Id,
                    Email = user.Email ?? "",
                    FullName = member?.FullName ?? "",
                    MemberId = member?.Id,
                    WalletBalance = member?.WalletBalance ?? 0,
                    RankLevel = member?.RankLevel ?? 3.5,
                    Tier = member?.Tier.ToString() ?? "Standard",
                    Roles = roles.ToList()
                }
            });
        }

        /// <summary>
        /// POST /api/auth/register
        /// Đăng ký tài khoản mới
        /// </summary>
        [HttpPost("register")]
        public async Task<ActionResult<AuthResponse>> Register([FromBody] RegisterRequest request)
        {
            var existingUser = await _userManager.FindByEmailAsync(request.Email);
            if (existingUser != null)
            {
                return BadRequest(new AuthResponse
                {
                    Success = false,
                    Message = "Email đã được sử dụng"
                });
            }

            var user = new IdentityUser
            {
                UserName = request.Email,
                Email = request.Email,
                EmailConfirmed = true
            };

            var result = await _userManager.CreateAsync(user, request.Password);
            if (!result.Succeeded)
            {
                return BadRequest(new AuthResponse
                {
                    Success = false,
                    Message = string.Join(", ", result.Errors.Select(e => e.Description))
                });
            }

            // Tạo Member profile
            var member = new Member
            {
                UserId = user.Id,
                FullName = request.FullName,
                WalletBalance = 0,
                Tier = MemberTier.Standard,
                JoinDate = DateTime.UtcNow,
                IsActive = true
            };
            _context.Members.Add(member);
            await _context.SaveChangesAsync();

            // Assign default role
            if (!await _roleManager.RoleExistsAsync("Member"))
            {
                await _roleManager.CreateAsync(new IdentityRole("Member"));
            }
            await _userManager.AddToRoleAsync(user, "Member");

            var roles = await _userManager.GetRolesAsync(user);
            var token = GenerateJwtToken(user, roles, member);

            return Ok(new AuthResponse
            {
                Success = true,
                Token = token,
                ExpiresAt = DateTime.UtcNow.AddMinutes(int.Parse(_configuration["Jwt:ExpireMinutes"] ?? "1440")),
                Message = "Đăng ký thành công",
                User = new UserInfo
                {
                    UserId = user.Id,
                    Email = user.Email ?? "",
                    FullName = member.FullName,
                    MemberId = member.Id,
                    WalletBalance = member.WalletBalance,
                    RankLevel = member.RankLevel,
                    Tier = member.Tier.ToString(),
                    Roles = roles.ToList()
                }
            });
        }

        /// <summary>
        /// GET /api/auth/me
        /// Lấy thông tin user hiện tại
        /// </summary>
        [HttpGet("me")]
        [Authorize]
        public async Task<ActionResult<UserInfo>> GetCurrentUser()
        {
            var userId = _userManager.GetUserId(User);
            var user = await _userManager.FindByIdAsync(userId!);
            if (user == null)
                return Unauthorized();

            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
            var roles = await _userManager.GetRolesAsync(user);

            return Ok(new UserInfo
            {
                UserId = user.Id,
                Email = user.Email ?? "",
                FullName = member?.FullName ?? "",
                MemberId = member?.Id,
                WalletBalance = member?.WalletBalance ?? 0,
                RankLevel = member?.RankLevel ?? 3.5,
                Tier = member?.Tier.ToString() ?? "Standard",
                Roles = roles.ToList()
            });
        }

        private string GenerateJwtToken(IdentityUser user, IList<string> roles, Member? member)
        {
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(
                _configuration["Jwt:Key"] ?? "YourSuperSecretKeyForPikApiThatShouldBeAtLeast32CharactersLong2026!"));
            var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id),
                new Claim(ClaimTypes.Email, user.Email ?? ""),
                new Claim(ClaimTypes.Name, member?.FullName ?? user.Email ?? ""),
                new Claim("MemberId", member?.Id.ToString() ?? "")
            };

            foreach (var role in roles)
            {
                claims.Add(new Claim(ClaimTypes.Role, role));
            }

            var expires = DateTime.UtcNow.AddMinutes(
                int.Parse(_configuration["Jwt:ExpireMinutes"] ?? "1440"));

            var token = new JwtSecurityToken(
                issuer: _configuration["Jwt:Issuer"] ?? "PikApi",
                audience: _configuration["Jwt:Audience"] ?? "PikApiClients",
                claims: claims,
                expires: expires,
                signingCredentials: credentials
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}
