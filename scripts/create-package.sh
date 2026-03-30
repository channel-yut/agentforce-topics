#!/bin/bash
# Agentforce Topics - Unlocked Package Creation Script

set -e

echo "=========================================="
echo "  Agentforce Topics パッケージ作成"
echo "=========================================="
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Dev Hub is configured
echo "📋 Step 1: Dev Hub確認"
DEV_HUB=$(sf config get target-dev-hub --json | jq -r '.result[0].value // empty')

if [ -z "$DEV_HUB" ]; then
    echo -e "${RED}❌ Dev Hubが設定されていません${NC}"
    echo ""
    echo "以下のコマンドでDev Hubにログインしてください："
    echo "  sf org login web --alias my-devhub --set-default-dev-hub"
    echo ""
    exit 1
fi

echo -e "${GREEN}✅ Dev Hub: $DEV_HUB${NC}"
echo ""

# Check if package already exists
echo "📦 Step 2: パッケージ確認"
PACKAGE_EXISTS=$(sf package list --target-dev-hub "$DEV_HUB" --json | jq -r '.result[] | select(.Name == "Agentforce Topics") | .Id // empty')

if [ -z "$PACKAGE_EXISTS" ]; then
    echo -e "${YELLOW}⚠️  パッケージが存在しません。作成します...${NC}"

    # Create package
    echo ""
    echo "📦 Step 3: パッケージ作成中..."
    sf package create \
        --name "Agentforce Topics" \
        --description "AI-Powered Insights System with Self-Learning Capabilities" \
        --package-type Unlocked \
        --path force-app \
        --target-dev-hub "$DEV_HUB"

    echo -e "${GREEN}✅ パッケージ作成完了${NC}"
else
    echo -e "${GREEN}✅ パッケージは既に存在します (ID: $PACKAGE_EXISTS)${NC}"
fi

echo ""

# Create package version
echo "📦 Step 4: パッケージバージョン作成中..."
echo -e "${YELLOW}⚠️  この処理には10-20分かかります${NC}"
echo ""

sf package version create \
    --package "Agentforce Topics" \
    --installation-key-bypass \
    --wait 20 \
    --target-dev-hub "$DEV_HUB" \
    --json > /tmp/package-version-result.json

# Check result
if [ $? -eq 0 ]; then
    PACKAGE_VERSION_ID=$(cat /tmp/package-version-result.json | jq -r '.result.SubscriberPackageVersionId')
    echo ""
    echo -e "${GREEN}=========================================="
    echo "  ✅ パッケージバージョン作成成功！"
    echo "==========================================${NC}"
    echo ""
    echo "📦 Subscriber Package Version ID:"
    echo "   $PACKAGE_VERSION_ID"
    echo ""
    echo "📋 次のステップ:"
    echo "   1. Promote (Production配布用):"
    echo "      sf package version promote --package $PACKAGE_VERSION_ID --target-dev-hub $DEV_HUB"
    echo ""
    echo "   2. インストール:"
    echo "      sf package install --package $PACKAGE_VERSION_ID --target-org your-org-alias --wait 10"
    echo ""
    echo "   3. README.mdにパッケージIDを記録:"
    echo "      **パッケージID**: $PACKAGE_VERSION_ID"
    echo ""
else
    echo -e "${RED}❌ パッケージバージョン作成に失敗しました${NC}"
    cat /tmp/package-version-result.json | jq '.'
    exit 1
fi

rm /tmp/package-version-result.json
