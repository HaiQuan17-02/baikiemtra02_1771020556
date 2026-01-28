using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PikApi.Migrations
{
    /// <inheritdoc />
    public partial class AddMatchRequests : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "888_MatchRequests",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CreatorMemberId = table.Column<int>(type: "int", nullable: false),
                    Title = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    PlayDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    StartTime = table.Column<TimeSpan>(type: "time", nullable: false),
                    EndTime = table.Column<TimeSpan>(type: "time", nullable: false),
                    CourtId = table.Column<int>(type: "int", nullable: true),
                    MaxPlayers = table.Column<int>(type: "int", nullable: false),
                    SkillLevelMin = table.Column<double>(type: "float", nullable: false),
                    SkillLevelMax = table.Column<double>(type: "float", nullable: false),
                    Status = table.Column<int>(type: "int", nullable: false),
                    CreatedDate = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_888_MatchRequests", x => x.Id);
                    table.ForeignKey(
                        name: "FK_888_MatchRequests_888_Courts_CourtId",
                        column: x => x.CourtId,
                        principalTable: "888_Courts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_888_MatchRequests_888_Members_CreatorMemberId",
                        column: x => x.CreatorMemberId,
                        principalTable: "888_Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "888_MatchRequestParticipants",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    MatchRequestId = table.Column<int>(type: "int", nullable: false),
                    MemberId = table.Column<int>(type: "int", nullable: false),
                    JoinedDate = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_888_MatchRequestParticipants", x => x.Id);
                    table.ForeignKey(
                        name: "FK_888_MatchRequestParticipants_888_MatchRequests_MatchRequestId",
                        column: x => x.MatchRequestId,
                        principalTable: "888_MatchRequests",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_888_MatchRequestParticipants_888_Members_MemberId",
                        column: x => x.MemberId,
                        principalTable: "888_Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_888_MatchRequestParticipants_MatchRequestId",
                table: "888_MatchRequestParticipants",
                column: "MatchRequestId");

            migrationBuilder.CreateIndex(
                name: "IX_888_MatchRequestParticipants_MemberId",
                table: "888_MatchRequestParticipants",
                column: "MemberId");

            migrationBuilder.CreateIndex(
                name: "IX_888_MatchRequests_CourtId",
                table: "888_MatchRequests",
                column: "CourtId");

            migrationBuilder.CreateIndex(
                name: "IX_888_MatchRequests_CreatorMemberId",
                table: "888_MatchRequests",
                column: "CreatorMemberId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "888_MatchRequestParticipants");

            migrationBuilder.DropTable(
                name: "888_MatchRequests");
        }
    }
}
