WITH AggregatedData AS
(
    SELECT
        [location],
        System.Timestamp() AS windowEndTime,
        AVG(iceThickness) AS avgIceThickness,
        MIN(iceThickness) AS minIceThickness,
        MAX(iceThickness) AS maxIceThickness,
        AVG(surfaceTemperature) AS avgSurfaceTemperature,
        MIN(surfaceTemperature) AS minSurfaceTemperature,
        MAX(surfaceTemperature) AS maxSurfaceTemperature,
        MAX(snowAccumulation) AS maxSnowAccumulation,
        AVG(externalTemperature) AS avgExternalTemperature,
        COUNT(*) AS readingCount
    FROM sensorinput TIMESTAMP BY timestamp
    GROUP BY
        [location],
        TumblingWindow(minute, 5)
),

FinalData AS
(
    SELECT
        CONCAT(
            [location], '-',
            REPLACE(REPLACE(REPLACE(CAST(windowEndTime AS nvarchar(max)), ':', ''), '-', ''), ' ', '')
        ) AS id,
        [location],
        windowEndTime,
        avgIceThickness,
        minIceThickness,
        maxIceThickness,
        avgSurfaceTemperature,
        minSurfaceTemperature,
        maxSurfaceTemperature,
        maxSnowAccumulation,
        avgExternalTemperature,
        readingCount,
        CASE
            WHEN avgIceThickness >= 30 AND avgSurfaceTemperature <= -2 THEN 'Safe'
            WHEN avgIceThickness >= 25 AND avgSurfaceTemperature <= 0 THEN 'Caution'
            ELSE 'Unsafe'
        END AS safetyStatus
    FROM AggregatedData
)

SELECT
    *
INTO cosmosoutput
FROM FinalData;

SELECT
    location,
    windowEndTime,
    avgIceThickness,
    minIceThickness,
    maxIceThickness,
    avgSurfaceTemperature,
    minSurfaceTemperature,
    maxSurfaceTemperature,
    maxSnowAccumulation,
    avgExternalTemperature,
    readingCount,
    safetyStatus
INTO bloboutput
FROM FinalData;