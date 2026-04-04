const admin = require('firebase-admin');
const fs = require('fs');
const crypto = require('crypto');

// node scripts/geojsonupload.js

const serviceAccount = require('./test-beach-circle-firebase-adminsdk-fbsvc-b5892c2483.json'); 

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

//flatten to coords for uploading to firebase
function processCoordinates(geometry) {
  const type = geometry['type'];
  const coords = geometry['coordinates'];

  if (type === 'Point') {
    // Point is just [lng, lat], store as a single object
    const [lng, lat] = coords;
    return { coords: [{ lng, lat }], geometry_type: type };
  }

  if (type === 'Polygon') {
    // [[[lng, lat], ...]] → [{lng, lat}, ...]
    return {
      coords: coords[0].map(([lng, lat]) => ({ lng, lat })),
      geometry_type: type,
    };
  }

  if (type === 'MultiPolygon') {
    // [[[[lng, lat], ...]], ...] → [{lng, lat}, ...] (flattens all rings)
    return {
      coords: coords.flat(2).map(([lng, lat]) => ({ lng, lat })),
      geometry_type: type,
    };
  }

  console.warn(`Unknown geometry type: ${type}`);
  return { coords: [], geometry_type: type };
}

async function main() {
  console.log('Starting building upload...');

  try {
    // Read GeoJSON file
    const geoJsonString = fs.readFileSync('../assets/csulb.geojson', 'utf8');
    const geoJson = JSON.parse(geoJsonString);
    const features = geoJson['features'];

    console.log(`Found ${features.length} buildings to upload`);

    let successCount = 0;
    let failCount = 0;

    for (const feature of features) {
      try {
        const properties = feature['properties'] ?? {};
        const geometry = feature['geometry'] ?? {};

        const buildingId = feature['id'];
            if (!buildingId) {
            throw new Error(`Feature missing id: ${properties['name']}`);
            }

        const { coords, geometry_type } = processCoordinates(geometry);

        const data = {
          name: properties['name'] ?? 'Unnamed Building',
          feature_type: properties['feature_type'] ?? 'building',
          coords,
          geometry_type,
          last_updated: admin.firestore.FieldValue.serverTimestamp(),
          // optional fields here
          ...(properties['abbrev'] && { abbrev: properties['abbrev'] }),
        };

        await db.collection('buildings').doc(buildingId).set(data, { merge: true });
        console.log(`Uploaded: ${data.name}`);

        successCount++;
      } catch (e) {
        console.log(`Failed: ${e.message}`);
        failCount++;
      }
    }

    console.log('\n=== Upload Complete ===');
    console.log(`Success: ${successCount}`);
    console.log(`Failed: ${failCount}`);
    console.log(`Total: ${features.length}`);

  } catch (e) {
    console.error('Error:', e.message);
    process.exit(1);
  }

  process.exit(0);
}

main();