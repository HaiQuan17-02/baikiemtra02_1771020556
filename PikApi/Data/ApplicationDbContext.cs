using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using PikApi.Entities;

namespace PikApi.Data
{
    public class ApplicationDbContext : IdentityDbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options)
        {
        }

        public DbSet<Member> Members { get; set; }
        public DbSet<WalletTransaction> WalletTransactions { get; set; }
        public DbSet<Court> Courts { get; set; }
        public DbSet<Booking> Bookings { get; set; }
        public DbSet<Tournament> Tournaments { get; set; }
        public DbSet<TournamentParticipant> TournamentParticipants { get; set; }
        public DbSet<Match> Matches { get; set; }
        public DbSet<MatchRequest> MatchRequests { get; set; }
        public DbSet<MatchRequestParticipant> MatchRequestParticipants { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Configure Member
            modelBuilder.Entity<Member>(entity =>
            {
                entity.HasIndex(e => e.UserId).IsUnique();
                entity.Property(e => e.WalletBalance).HasDefaultValue(0m);
                entity.Property(e => e.TotalSpent).HasDefaultValue(0m);
            });

            // Configure WalletTransaction
            modelBuilder.Entity<WalletTransaction>(entity =>
            {
                entity.HasOne(e => e.Member)
                    .WithMany(m => m.WalletTransactions)
                    .HasForeignKey(e => e.MemberId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // Configure Court
            modelBuilder.Entity<Court>(entity =>
            {
                entity.Property(e => e.IsActive).HasDefaultValue(true);
            });

            // Configure Booking
            modelBuilder.Entity<Booking>(entity =>
            {
                entity.HasOne(e => e.Court)
                    .WithMany(c => c.Bookings)
                    .HasForeignKey(e => e.CourtId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(e => e.Member)
                    .WithMany(m => m.Bookings)
                    .HasForeignKey(e => e.MemberId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(e => e.ParentBooking)
                    .WithMany(b => b.ChildBookings)
                    .HasForeignKey(e => e.ParentBookingId)
                    .OnDelete(DeleteBehavior.Restrict);

                // RowVersion is configured automatically with [Timestamp] attribute
                entity.Property(e => e.RowVersion)
                    .IsRowVersion();
            });

            // Configure Tournament Relationship
            modelBuilder.Entity<TournamentParticipant>(entity =>
            {
                entity.HasOne(e => e.Tournament)
                    .WithMany(t => t.Participants)
                    .HasForeignKey(e => e.TournamentId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(e => e.Member)
                    .WithMany()
                    .HasForeignKey(e => e.MemberId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

             modelBuilder.Entity<Match>(entity =>
            {
                entity.HasOne(e => e.Tournament)
                    .WithMany(t => t.Matches)
                    .HasForeignKey(e => e.TournamentId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(e => e.Team1)
                    .WithMany()
                    .HasForeignKey(e => e.Team1_MemberId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(e => e.Team2)
                    .WithMany()
                    .HasForeignKey(e => e.Team2_MemberId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // Configure MatchRequest
            modelBuilder.Entity<MatchRequest>(entity =>
            {
                entity.HasOne(e => e.Creator)
                    .WithMany()
                    .HasForeignKey(e => e.CreatorMemberId)
                    .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(e => e.Court)
                    .WithMany()
                    .HasForeignKey(e => e.CourtId)
                    .OnDelete(DeleteBehavior.SetNull);
            });

            // Configure MatchRequestParticipant
            modelBuilder.Entity<MatchRequestParticipant>(entity =>
            {
                entity.HasOne(e => e.MatchRequest)
                    .WithMany(m => m.Participants)
                    .HasForeignKey(e => e.MatchRequestId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(e => e.Member)
                    .WithMany()
                    .HasForeignKey(e => e.MemberId)
                    .OnDelete(DeleteBehavior.Restrict);
            });
        }
    }
}
