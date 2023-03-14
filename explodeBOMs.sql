CREATE OR REPLACE PROCEDURE `REDACTED_PROJECT.REDACTED_HOST.spExplodeBOM`()
-- Explodes All Levels of the Build of Material Table & Stores Records in a new table
BEGIN
  -- Declare and Set Variables for Exit Critera 
  DECLARE rd, td DATE;
  SET rd = CURRENT_DATE();
  SET td = (SELECT MAX(ts) FROM `REDACTED_PROJECT.REDACTED_HOST.explodedBOM`);

  -- Exit Routine When Run Date = Last Run Date
IF rd = td THEN RETURN; END IF;

    -- Create Temp Table Used in Loop (Faster than having to constantly unnest table each pass)
    BEGIN
      CREATE TEMPORARY TABLE tb AS
      SELECT 
        b.id bomID, 
        b.bom_name,
        o.product_code output,
        i.product_code input,
        i.quantity,
        i.input_uom_name UoM,
        b.is_built_on_the_fly BotF
      FROM `REDACTED_PROJECT.REDACTED_HOST.production_boms` b
      LEFT JOIN UNNEST(inputs) i
      LEFT JOIN UNNEST(outputs) o
      WHERE b.active = true
      ORDER BY o.product_code;
    END;
 
    -- If Outdated Table Exists Drop it
    DROP TABLE IF EXISTS `REDACTED_PROJECT.REDACTED_HOST.explodedBOM`;

    -- Create New Table for Results
    CREATE TABLE `REDACTED_PROJECT.REDACTED_HOST.explodedBOM`
    (
      bomID INT64 OPTIONS(description= 'Unique record Id of the BOM at current level'),
      bom_name STRING OPTIONS(description= 'bom_name at current level'),
      output STRING OPTIONS(description= 'output of inputs (topSku of current level)'),
      level INT64 OPTIONS(description= 'depth of an output and its inputs (0 Based, 0 = topBom)'),
      input STRING OPTIONS(description= 'inputs of output at current level'),
      quantity FLOAT64 OPTIONS(description= 'inputs qty required at current level'),
      UoM STRING OPTIONS(description= 'inputs unit of measurement at current level'),
      BotF BOOLEAN OPTIONS(description= 'build on the fly flag for output at current level'),
      topSku STRING OPTIONS(description= 'Top Most Sku (output when level = 0)'),
      topSkuBotF BOOLEAN OPTIONS(description= 'Build on the Fly Flag of Top Most Sku'),
      topBomName STRING OPTIONS(description= 'Top Most Bom Name'),
      topBomID INT64 OPTIONS(description= 'Unique record Id of the top most BOM.'),
      sequence INT64 OPTIONS(description= 'Sequence of BOM, BOM sortOrder Ten Based, 10 is dominate, 20 secondary, etc'),
      ts DATE DEFAULT CURRENT_DATE() OPTIONS(description= 'date recorded')   
    ) OPTIONS(description= 'Table Contains all Levels of a BOM, only contains/considers BOMs that were active on the date equal to column ts. (ORDER BY topSku, sequence, level, output) ');

    -- Insert Results to Fresh Table
    INSERT INTO `REDACTED_PROJECT.REDACTED_HOST.explodedBOM`
    (
      bomID,
      bom_name, 
      output, 
      level, 
      input, 
      quantity, 
      UoM, 
      BotF, 
      topSku, 
      topSkuBotF,
      topBomName, 
      topBomID,
      sequence
    )
    
   -- Explode Boms Using 'Recursive With' Loop
    WITH RECURSIVE RPL AS(
          SELECT 
            0 as level,
            ROOT.bomID,
            ROOT.bom_name,
            ROOT.output, 
            ROOT.input, 
            ROOT.quantity,
            ROOT.UoM, 
            ROOT.BotF, 
            ROOT.output AS topSku, 
            ROOT.BotF AS topSkuBotF,
            ROOT.bom_name AS topBomName, 
            ROOT.bomID AS topBomID
          FROM tb ROOT 
          UNION ALL 
          SELECT 
            PARENT.level+1,
            CHILD.bomID,
            CHILD.bom_name, 
            CHILD.output, 
            CHILD.input, 
            CHILD.quantity, 
            CHILD.UoM, 
            CHILD.BotF, 
            PARENT.topSku, 
            PARENT.topSkuBotF,
            PARENT.topBomName,
            PARENT.topBomID,
          FROM RPL PARENT, tb CHILD
          WHERE PARENT.input = CHILD.output
            AND PARENT.level < 10 -- e-brake  to stop the madness, (nothing currently has >5 Levels)
    )
    -- Fetch Results to Insert
    SELECT DISTINCT  
      bomID,
      bom_name, 
      output, 
      level, 
      input, 
      quantity, 
      UoM, 
      BotF, 
      topSku, 
      topSkuBotF, 
      topBomName,
      topBomID,
      sequence
    FROM RPL
    -- Appends Bom Sequence  
    LEFT JOIN (
      SELECT
        b.bom_id,
        b.sequence
      FROM `REDACTED_PROJECT.REDACTED_HOST.products`
      ,UNNEST(boms) b
    ) q ON q.bom_id = topBomID
    ORDER BY topSku, sequence, level, output;
    

END;
