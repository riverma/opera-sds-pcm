from unittest.mock import MagicMock, Mock

from pytest_mock import MockerFixture

import product2dataset.product2dataset


def test_convert__when_L3_HLS_PGE__adds_PST_metadata(mocker: MockerFixture):
    """Tests that PST metadata such as input granule ID and output product URLs are added to the root of the dataset metadata."""
    # ARRANGE
    create_mock_PGEOutputsConf(mocker)
    create_mock_SettingsConf(mocker)

    mocker.patch("product2dataset.product2dataset.process_outputs", return_value={
        "Primary": {
            "dummy_product": {
                "hashcheck": False
            }
        },
        "Secondary": {},
        "Optional": {}
    })

    extract_mock = Mock()
    extract_mock.extract.return_value = "dir1/dir2/dummy_product"
    extract_mock.PRODUCT_TYPES_KEY = "PRODUCT_TYPES"
    mocker.patch("product2dataset.product2dataset.extract", extract_mock)

    mocker.patch("product2dataset.product2dataset.glob.iglob", return_value=["dir1/dir2/dummy_product/dummy_product.met.json"])
    mocker.patch("builtins.open", mocker.mock_open(read_data="""
        {
            "dummy_met_json_entry_key": "dummy_met_json_entry_value",
            "FileSize": 0,
            "id": "dummy_product_id",
            "FileName": "dummy_product_filename"
        }
    """))
    mocker.patch("product2dataset.product2dataset.os.path.abspath", lambda _: f"/{_}")
    mocker.patch("product2dataset.product2dataset.os.unlink", Mock())

    # ACT
    created_datasets = product2dataset.product2dataset.convert(
        "dummy_product_dir",
        "L3_HLS",
        # kwargs below
        state_config_product_metadata={
            "B01": {"id": "dummy_granule_id.B01"},
            "@timestamp": ""
        })

    # ASSERT
    assert created_datasets == ["dir1/dir2/dummy_product"]


def create_mock_SettingsConf(mocker):
    mock_SettingsConf = MagicMock()
    mock_SettingsConf.cfg = {
        "PRODUCT_TYPES": {},
        "DATASET_BUCKET": "dummy_dataset_bucket",  # in actual system, added in terraform scripts
        "DATASET_S3_ENDPOINT": "dummy_dataset_s3_endpoint"  # in actual system, added in terraform scripts
    }
    mocker.patch("product2dataset.product2dataset.SettingsConf", return_value=mock_SettingsConf)


def create_mock_PGEOutputsConf(mocker):
    mock_PGEOutputsConf = MagicMock()
    mock_PGEOutputsConf.cfg = {
        "L3_HLS": {
            "Outputs": {}
        }
    }
    mocker.patch("product2dataset.product2dataset.PGEOutputsConf", return_value=mock_PGEOutputsConf)
