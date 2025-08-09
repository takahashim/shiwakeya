# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Shiwakeya is a Rails 8.0.2 web application that integrates Google Sheets with Money Forward (マネーフォワード) for financial data management and bookkeeping automation.

## Tech Stack

- **Framework**: Rails 8.0.2 with Propshaft asset pipeline
- **Database**: SQLite3 (with Solid Cache, Solid Queue, and Solid Cable for production)
- **CSS**: Tailwind CSS
- **Web Server**: Puma with Thruster for production
- **Deployment**: Kamal (Docker-based deployment)
- **Ruby Version**: Check `.ruby-version` file for current version

## Development Commands

### Initial Setup
```bash
bin/setup              # Install dependencies, prepare database, and start server
```

### Running the Application
```bash
bin/dev                # Start development server with Tailwind CSS watch mode (uses Procfile.dev)
bin/rails server       # Start Rails server only
bin/rails tailwindcss:watch  # Start Tailwind CSS watch mode
```

### Database Management
```bash
bin/rails db:create    # Create development and test databases
bin/rails db:migrate   # Run database migrations
bin/rails db:prepare   # Setup database (create, migrate, seed)
bin/rails db:drop      # Drop the database
bin/rails db:seed      # Load seed data
bin/rails db:reset     # Drop, create, migrate, and seed
```

### Code Quality
```bash
bin/rubocop            # Run RuboCop for Ruby code linting (uses .rubocop.yml with rails-omakase)
bin/brakeman           # Run security analysis
```

### Asset Management
```bash
bin/rails assets:precompile  # Compile assets for production
bin/rails assets:clean        # Remove old compiled assets
bin/rails assets:clobber      # Remove all compiled assets
```

### Console and Tasks
```bash
bin/rails console      # Start Rails console
bin/rails c            # Shorthand for console
bin/rails routes       # Show all application routes
bin/rails -T           # List all available rake tasks
```

## Architecture

### Application Structure
The application follows standard Rails MVC architecture:

- **Models** (`app/models/`): Active Record models for business logic and data persistence
- **Views** (`app/views/`): ERB templates with Tailwind CSS styling
- **Controllers** (`app/controllers/`): Request handling and response coordination
- **Assets** (`app/assets/`): Stylesheets and images managed by Propshaft
  - Tailwind CSS compiled output in `app/assets/builds/`
  - Source styles in `app/assets/stylesheets/` and `app/assets/tailwind/`

### Database Configuration
- Development: SQLite3 stored in `storage/development.sqlite3`
- Test: SQLite3 stored in `storage/test.sqlite3`
- Production: Multiple SQLite3 databases for primary, cache, queue, and cable
  - Migrations separated by purpose in `db/cache_migrate`, `db/queue_migrate`, `db/cable_migrate`

### Key Configuration Files
- `config/routes.rb`: Application routing
- `config/database.yml`: Database configuration
- `config/application.rb`: Main application configuration (module name: Shiwakeya)
- `Procfile.dev`: Development server processes (web server + Tailwind watch)

### Development Tools
- **Foreman**: Process manager for running multiple services in development
- **Debug gem**: Ruby debugging with remote connection support
- **Web Console**: Interactive console on error pages in development

## Google Sheets & Money Forward Integration

This application serves as a bridge between Google Sheets and Money Forward for automated bookkeeping and financial data synchronization. Implementation details for the integration should be added in:

- Controllers for handling OAuth and API endpoints
- Service objects for Google Sheets API interaction
- Service objects for Money Forward API interaction
- Background jobs for data synchronization
- Models for storing integration settings and mapping rules

## Development Workflow

1. Always run `bin/setup` after cloning or pulling major changes
2. Use `bin/dev` for development to ensure Tailwind CSS compilation
3. Run `bin/rubocop` before committing to maintain code quality
4. Security scanning with `bin/brakeman` is configured for development/test environments
5. Database changes should use Rails migrations (`bin/rails generate migration`)