#!/bin/bash +x
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#


#set -e

CHANNEL_NAME=$1
: ${CHANNEL_NAME:="person"}
echo $CHANNEL_NAME

TOTAL_CHANNELS=2

export FABRIC_ROOT=$PWD/../..
export FABRIC_CFG_PATH=$PWD/artifacts

echo

OS_ARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')

## Using docker-compose template replace private key file names with constants
function replacePrivateKey () {
	ARCH=`uname -s | grep Darwin`
	if [ "$ARCH" == "Darwin" ]; then
		OPTS="-it"
	else
		OPTS="-i"
	fi

	cp docker-compose-template.yaml docker-compose.yaml

        CURRENT_DIR=$PWD
        cd crypto-config/peerOrganizations/org1.example.com/ca/
        PRIV_KEY=$(ls *_sk)
        cd $CURRENT_DIR
        sed $OPTS "s/CA1_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose.yaml
        cd crypto-config/peerOrganizations/org2.example.com/ca/
        PRIV_KEY=$(ls *_sk)
        cd $CURRENT_DIR
        sed $OPTS "s/CA2_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose.yaml

	
	cp ./network/network-config-template.yaml ./network/network-config.yaml

	cd crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/
	M_KEY=$(ls *_sk)
	cd $CURRENT_DIR/network
	sed $OPTS "s/CA1_M_KEY/${M_KEY}/g" network-config.yaml
	cd $CURRENT_DIR/

	cd crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/keystore/
	M_KEY=$(ls *_sk)
	cd $CURRENT_DIR/network
	sed $OPTS "s/CA2_M_KEY/${M_KEY}/g" network-config.yaml
	cd $CURRENT_DIR/


}

function generateIdemixMaterial (){
        CURDIR=`pwd`
        IDEMIXGEN=$CURDIR/bin/idemixgen
        IDEMIXMATDIR=$CURDIR/crypto-config/idemix

        if [ -f "$IDEMIXGEN" ]; then
            echo "Using idemixgen -> $IDEMIXGEN"
        else
            echo "Building idemixgen"
            make -C $FABRIC_ROOT release
        fi

        echo
        echo "####################################################################"
        echo "##### Generate idemix crypto material using idemixgen tool #########"
        echo "####################################################################"

        mkdir -p $IDEMIXMATDIR
        cd $IDEMIXMATDIR

        # Generate the idemix issuer keys
        $IDEMIXGEN ca-keygen

        # Generate the idemix signer keys
        $IDEMIXGEN signerconfig -u OU1 -e OU1 -r 1

        cd $CURDIR
}
## Generates Org certs using cryptogen tool
function generateCerts (){
	CRYPTOGEN=./bin/cryptogen

	if [ -f "$CRYPTOGEN" ]; then
            echo "Using cryptogen -> $CRYPTOGEN"
	else
	    echo "Building cryptogen"
	    make -C $FABRIC_ROOT release
	fi

	echo
	echo "##########################################################"
	echo "##### Generate certificates using cryptogen tool #########"
	echo "##########################################################"
	$CRYPTOGEN generate --config=./cryptogen.yaml
	echo
}

## Generate orderer genesis block , channel configuration transaction and anchor peer update transactions
function generateChannelArtifacts() {

	CONFIGTXGEN=./bin/configtxgen
	if [ -f "$CONFIGTXGEN" ]; then
            echo "Using configtxgen -> $CONFIGTXGEN"
	else
	    echo "Building configtxgen"
	    make -C $FABRIC_ROOT release
	fi

	echo "##########################################################"
	echo "#########  Generating Orderer Genesis block ##############"
	echo "##########################################################"
	# Note: For some unknown reason (at least for now) the block file can't be
	# named orderer.genesis.block or the orderer will fail to launch!
	$CONFIGTXGEN -profile TwoOrgsOrdererGenesis -channelID test-orderer-syschan -outputBlock ./channel/genesis.block

        for ((i = 1; i <= $TOTAL_CHANNELS; i = $i + 1)); do
                echo
                echo "#################################################################"
                echo "### Generating channel configuration transaction '$CHANNEL_NAME$i.tx' ###"
                echo "#################################################################"
		$CONFIGTXGEN -profile TwoOrgsChannel -outputCreateChannelTx ./channel/$CHANNEL_NAME$i.tx -channelID $CHANNEL_NAME$i
		echo
	done

        for ((i = 1; i <= $TOTAL_CHANNELS; i = $i + 1)); do
		echo
		echo "#################################################################"
		echo "#######    Generating anchor peer update for OrgMSP   ##########"
		echo "#################################################################"
		$CONFIGTXGEN -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel/Org${i}MSPanchors.tx -channelID $CHANNEL_NAME$i -asOrg Org${i}MSP
		echo
	done

}

cd $FABRIC_CFG_PATH/
rm -rf crypto-config/*
rm -rf channel/*

generateCerts
generateIdemixMaterial
replacePrivateKey
generateChannelArtifacts

