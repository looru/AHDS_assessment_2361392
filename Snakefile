configfile: "config.yaml"

TEST       = config.get("test", True)
FULL_MAX   = int(config.get("max_articles", 10000))
TEST_N     = int(config.get("test_n", 20))
SEARCHTERM = config["search_term"]

N_ARTICLES = TEST_N if TEST else FULL_MAX
