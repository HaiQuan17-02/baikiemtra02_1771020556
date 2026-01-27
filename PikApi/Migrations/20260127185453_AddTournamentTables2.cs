using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PikApi.Migrations
{
    /// <inheritdoc />
    public partial class AddTournamentTables2 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "888_Tournaments",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    StartDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    EndDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    EntryFee = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    PrizePool = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    Status = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_888_Tournaments", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "888_Matches",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    TournamentId = table.Column<int>(type: "int", nullable: false),
                    RoundName = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Team1_MemberId = table.Column<int>(type: "int", nullable: true),
                    Team2_MemberId = table.Column<int>(type: "int", nullable: true),
                    Score1 = table.Column<int>(type: "int", nullable: false),
                    Score2 = table.Column<int>(type: "int", nullable: false),
                    Winner = table.Column<int>(type: "int", nullable: false),
                    Status = table.Column<int>(type: "int", nullable: false),
                    NextMatchId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_888_Matches", x => x.Id);
                    table.ForeignKey(
                        name: "FK_888_Matches_888_Members_Team1_MemberId",
                        column: x => x.Team1_MemberId,
                        principalTable: "888_Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_888_Matches_888_Members_Team2_MemberId",
                        column: x => x.Team2_MemberId,
                        principalTable: "888_Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_888_Matches_888_Tournaments_TournamentId",
                        column: x => x.TournamentId,
                        principalTable: "888_Tournaments",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "888_TournamentParticipants",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    TournamentId = table.Column<int>(type: "int", nullable: false),
                    MemberId = table.Column<int>(type: "int", nullable: false),
                    IsFeePaid = table.Column<bool>(type: "bit", nullable: false),
                    JoinedDate = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_888_TournamentParticipants", x => x.Id);
                    table.ForeignKey(
                        name: "FK_888_TournamentParticipants_888_Members_MemberId",
                        column: x => x.MemberId,
                        principalTable: "888_Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_888_TournamentParticipants_888_Tournaments_TournamentId",
                        column: x => x.TournamentId,
                        principalTable: "888_Tournaments",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_888_Matches_Team1_MemberId",
                table: "888_Matches",
                column: "Team1_MemberId");

            migrationBuilder.CreateIndex(
                name: "IX_888_Matches_Team2_MemberId",
                table: "888_Matches",
                column: "Team2_MemberId");

            migrationBuilder.CreateIndex(
                name: "IX_888_Matches_TournamentId",
                table: "888_Matches",
                column: "TournamentId");

            migrationBuilder.CreateIndex(
                name: "IX_888_TournamentParticipants_MemberId",
                table: "888_TournamentParticipants",
                column: "MemberId");

            migrationBuilder.CreateIndex(
                name: "IX_888_TournamentParticipants_TournamentId",
                table: "888_TournamentParticipants",
                column: "TournamentId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "888_Matches");

            migrationBuilder.DropTable(
                name: "888_TournamentParticipants");

            migrationBuilder.DropTable(
                name: "888_Tournaments");
        }
    }
}
