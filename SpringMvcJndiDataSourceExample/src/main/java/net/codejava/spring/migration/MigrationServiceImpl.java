package net.codejava.spring.migration;

import javax.sql.DataSource;

import org.flywaydb.core.Flyway;

public class MigrationServiceImpl implements MigrationService {
	
	private final DataSource dataSource;
	
	public MigrationServiceImpl(DataSource dataSource) {
		this.dataSource=dataSource;
	}

	
	/* (non-Javadoc)
	 * @see net.codejava.spring.migration.Migration#migrate()
	 */
	@Override
	public void migrate() {
        Flyway flyway = new Flyway();
        flyway.setDataSource(dataSource);
        flyway.setValidateOnMigrate(false);
        flyway.info();
        flyway.migrate();
    }

}
